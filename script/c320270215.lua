local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon Procedure: 2+ "Batteryman" monsters
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x28),2,99)

	-- Effect 1: When Link Summoned: Destroy up to 3 cards (up to 2 from field, up to 1 from hand)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	-- Effect 2: Once per turn: Gain 1000 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- Effect 3: When declaring an attack: Opponent cannot activate monster effects during this Battle Phase
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetOperation(s.lockop)
	c:RegisterEffect(e3)

	-- Effect 4: Unaffected by card effects except "Batteryman" cards or Thunder monsters
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_IMMUNE_EFFECT)
	e4:SetValue(s.efilter)
	c:RegisterEffect(e4)
end

s.listed_series={0x28,0xff3} -- "Batteryman" (0x28) and "Voltech" (0xff3)

-- Effect 1 (Destroy targeting logic)
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
			or Duel.IsExistingTarget(nil,tp,LOCATION_HAND,LOCATION_HAND,1,nil)
	end
	
	local g=Group.CreateGroup()
	local field_g=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil,e)
	local hand_g=Duel.GetMatchingGroup(Card.IsCanBeEffectTarget,tp,LOCATION_HAND,LOCATION_HAND,nil,e)
	
	local max_f=math.min(#field_g, 2)
	local max_h=math.min(#hand_g, 1)
	
	-- Select targets on the field (up to 2)
	local tg_f=Group.CreateGroup()
	if max_f>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then -- Prompt: "Target card(s) on the field?"
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		tg_f=Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,max_f,nil)
		g:Merge(tg_f)
	end
	
	-- Select target in hand (up to 1)
	if max_h>0 and (#g==0 or Duel.SelectYesNo(tp,aux.Stringid(id,4))) then -- Prompt: "Target a card in hand?"
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local tg_h=Duel.SelectTarget(tp,nil,tp,LOCATION_HAND,LOCATION_HAND,1,1,g)
		g:Merge(tg_h)
	end
	
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

-- Effect 2 (ATK Gain logic)
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-- Effect 3 (Attack lock logic)
function s.lockop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_BATTLE)
	Duel.RegisterEffect(e1,tp)
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
end

-- Effect 4 (Immunity logic)
function s.efilter(e,re)
	local rc=re:GetOwner()
	if not rc then return true end
	-- Affected by "Batteryman" cards or Thunder monsters
	local is_batteryman=rc:IsSetCard(0x28)
	local is_thunder=rc:IsType(TYPE_MONSTER) and rc:IsRace(RACE_THUNDER)
	return not (is_batteryman or is_thunder)
end