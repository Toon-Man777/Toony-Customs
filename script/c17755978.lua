local s,id=GetID()
function s.initial_effect(c)
	-- 1st Effect: Special Summon from hand (Quick Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	-- Unrespondable: Cannot be negated or responded to
	e1:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISEFFECT+EFFECT_FLAG_CANNOT_CHHAIN)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2nd Effect: Search + Token Generation
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	-- Static: No Damage while on field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(0)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EFFECT_NO_EFFECT_DAMAGE)
	c:RegisterEffect(e3b)

	-- Static: Attack Position Effects
	-- Battle Protection for Kuribohs (0xa4)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetCondition(function(e) return e:GetHandler():IsAttack() end)
	e4:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xa4))
	e4:SetValue(1)
	c:RegisterEffect(e4)
	-- ATK Boost: 500 per Kuriboh on field
	local e4b=Effect.CreateEffect(c)
	e4b:SetType(EFFECT_TYPE_FIELD)
	e4b:SetCode(EFFECT_UPDATE_ATTACK)
	e4b:SetRange(LOCATION_MZONE)
	e4b:SetTargetRange(LOCATION_MZONE,0)
	e4b:SetCondition(function(e) return e:GetHandler():IsAttack() end)
	e4b:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xa4))
	e4b:SetValue(s.atkval)
	c:RegisterEffect(e4b)

	-- Static: Defense Position Effects
	-- Immunity for Kuribohs (0xa4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(LOCATION_MZONE,0)
	e5:SetCondition(function(e) return e:GetHandler():IsDefense() end)
	e5:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xa4))
	e5:SetValue(function(e,re) return e:GetHandlerPlayer()~=re:GetOwnerPlayer() end)
	c:RegisterEffect(e5)
	-- DEF Boost: 500 per Kuriboh you control
	local e5b=Effect.CreateEffect(c)
	e5b:SetType(EFFECT_TYPE_FIELD)
	e5b:SetCode(EFFECT_UPDATE_DEFENSE)
	e5b:SetRange(LOCATION_MZONE)
	e5b:SetTargetRange(LOCATION_MZONE,0)
	e5b:SetCondition(function(e) return e:GetHandler():IsDefense() end)
	e5b:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xa4))
	e5b:SetValue(s.defval)
	c:RegisterEffect(e5b)

	-- Damage Tracking
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_DAMAGE)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end

-- Hand Trigger Condition: Took damage this turn
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(ep,id,RESET_PHASE+PHASE_END,0,1)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFlagEffect(tp,id)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
	end
end

-- Search Logic: Setcodes 0xa4 (Kuriboh) and 0xf00 (Zero)
function s.thfilter(c)
	return (c:IsSetCard(0xa4) or c:IsSetCard(0xf00)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		-- Special Summon tokens as many as possible
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 or not Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN,300,200,1,RACE_FIEND,ATTRIBUTE_DARK,POS_FACEUP_DEFENSE) then return end
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUE_EYES_SPIRIT) then ft=1 end
		for i=1,ft do
			local token=Duel.CreateToken(tp,id+1)
			Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		end
		Duel.SpecialSummonComplete()
	end
end

-- Stat Boost Calculations
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsSetCard,0,LOCATION_MZONE,LOCATION_MZONE,nil,0xa4)*500
end
function s.defval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsSetCard,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil,0xa4)*500
end