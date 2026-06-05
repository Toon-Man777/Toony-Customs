local s,id=GetID()
function s.initial_effect(c)
	-- 1. Activate: Fusion Summon using Union monsters from Hand or DECK
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	-- 2. GY Effect: Banish this card to add 1 banished Union monster to hand
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id) -- "You can only use this effect of 'Hangar Polymerization' once per turn"
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Filter: Materials must be Union monsters
function s.ffilter(c)
	return c:IsType(TYPE_UNION)
end

-- Check if the Fusion Monster can be summoned using our specific rules
function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,chkf)
end

-- 1. Fusion Activation Target
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		-- Gather available materials from Hand and DECK that are Union monsters
		local mg=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
		local res=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- 1. Fusion Activation Operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	-- Lock player into Union monsters for the rest of the turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2)) -- Displays lock UI to player
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	-- Resolve Fusion Summon
	local mg=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
	local tc=g:GetFirst()
	if tc then
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end

-- Restrict special summons to ONLY Union monsters
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsType(TYPE_UNION)
end

-- 2. GY Salvage Target
function s.thfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_UNION) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

-- 2. GY Salvage Operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end