local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon: 3 "D/D/D" monsters
	Fusion.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x10af),3)
	c:EnableReviveSelection()

	-- Effect 1: Gain LP and boost ATK
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	-- Quick Effect condition if Oracle King d'Arc is used
	e1:SetCondition(s.atkcon)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
	-- Duplicate for Quick Effect timing
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetCondition(s.qatkcon)
	c:RegisterEffect(e2)

	-- Effect 2: Opponent cannot inflict burn damage
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,1)
	e3:SetValue(s.aclimit)
	c:RegisterEffect(e3)

	-- Effect 3: Floating effect when leaving the field
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- Setcodes: D/D (0xaf), D/D/D (0x10af)
s.listed_names={15949273} -- D/D/D Oracle King d'Arc

-- Logic for Effect 1 (ATK and LP)
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():GetMaterial():IsExists(Card.IsCode,1,nil,15949273)
end
function s.qatkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetMaterial():IsExists(Card.IsCode,1,nil,15949273)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(aux.FilterFaceupFunction(Card.IsSetCard,0x10af),tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPPO)
	local g1=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELF)
	local g2=Duel.SelectTarget(tp,aux.FilterFaceupFunction(Card.IsSetCard,0x10af),tp,LOCATION_MZONE,0,1,1,nil)
	e:SetLabelObject(g1:GetFirst())
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,g1:GetFirst():GetAttack())
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g<2 then return end
	local tc_oppo=g:Filter(Card.IsControler,nil,1-tp):GetFirst()
	local tc_self=g:Filter(Card.IsControler,nil,tp):GetFirst()
	if tc_oppo and tc_oppo:IsFaceup() and tc_self and tc_self:IsFaceup() then
		local atk=tc_oppo:GetAttack()
		if Duel.Recover(tp,atk,REASON_EFFECT)>0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc_self:RegisterEffect(e1)
		end
	end
end

-- Logic for Effect 2 (Anti-Burn)
function s.aclimit(e,re,tp)
	local ex,g,gc,dp,dv=Duel.GetOperationInfo(ev,CATEGORY_DAMAGE)
	return ex or re:GetCategory()&CATEGORY_DAMAGE~=0
end

-- Logic for Effect 3 (Floating)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousControler(tp) and rp==1-tp and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x10af) and c:IsLevelRankBelow(8) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (c:IsLocation(LOCATION_EXTRA) or c:IsLocation(LOCATION_GRAVE))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end