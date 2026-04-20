local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Ritual Summoning Requirement
	-- Effect 1: Banish opponent's monster at start of Damage Step
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_BATTLE_START)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	-- Effect 2: End Phase Burn (300 per banished card)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)

	-- Effect 3: Floating effect upon destruction
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	-- Global Tracker for banished cards
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_REMOVE)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
end

s.listed_names={21082832} -- Chaos Form

-- Banish Logic
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=e:GetHandler():GetBattleTarget()
	if chk==0 then return tc and tc:IsControler(1-tp) and tc:IsAbleToRemove() end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetHandler():GetBattleTarget()
	if tc and tc:IsRelateToBattle() then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

-- Burn Logic
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		if tc:IsPreviousControler(1-tp) then
			Duel.RegisterFlagEffect(1-tp,id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ct=Duel.GetFlagEffect(1-tp,id)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*300)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetFlagEffect(1-tp,id)
	if ct>0 then
		Duel.Damage(1-tp,ct*300,REASON_EFFECT)
	end
end

-- Special Summon Floating Logic
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_BATTLE) or (rp==1-tp and c:IsReason(REASON_EFFECT))
end
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_DRAGON) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end