local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon materials: "Meklord Emperor Granel" + 1+ non-Tuner Machine monsters
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,s.tunerfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)

	-- 1. Custom Summon Rule: Treat 1 "Meklord Emperor Granel" you control as a Tuner
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SYNCHRO_MATERIAL_CUSTOM)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetTarget(s.synctg)
	e1:SetOperation(s.syncop)
	c:RegisterEffect(e1)

	-- 2. Ignition Effect: Target 1 opponent's monster Special Summoned from the Extra Deck; equip it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
	aux.AddEReferChanged(c)

	-- 3. Continuous Effect: Gains ATK/DEF equal to half your LP
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.lpval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)

	-- 4. Continuous Effect: Gains ATK equal to the ATK of the monster equipped by its own effect
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(s.eqatkval)
	c:RegisterEffect(e5)

	-- 5. Continuous Effect: Inflict piercing battle damage
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e6)

	-- 6. Ignition Effect: Target 1 monster equipped to this card; Special Summon it
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e7:SetRange(LOCATION_MZONE)
	e7:SetTarget(s.sptg)
	e7:SetOperation(s.spop)
	c:RegisterEffect(e7)
end

s.listed_names={4545683}

-- Material filters
function s.tunerfilter(c,scard,sumtype,tp)
	return c:IsCode(4545683) and c:IsType(TYPE_TUNER,scard,sumtype,tp)
end
function s.customtunerfilter(c,scard,sumtype,tp)
	return c:IsCode(4545683) and c:IsFaceup()
end

-- 1. Custom Synchro Material Logic
function s.synctg(e,tg,ntg,sg,lv,sc,tp)
	return Synchro.ConditionMinMax(tg,ntg,sg,lv,sc,tp,s.customtunerfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)
end
function s.syncop(e,tp,eg,ep,ev,re,r,rp,tg,ntg,sg,lv,sc)
	return Synchro.OperationMinMax(tg,ntg,sg,lv,sc,tp,s.customtunerfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)
end

-- 2. Equip Logic
function s.eqfilter(c)
	return c:IsFaceup() and c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsSummonLocation(LOCATION_EXTRA) and c:IsAbleToChangeControler()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.eqfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.eqfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectTarget(tp,s.eqfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		if c:IsFaceup() and c:IsRelateToEffect(e) then
			if not Duel.Equip(tp,tc,c) then return end
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetValue(s.eqlimit)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		else
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end
	end
end
function s.eqlimit(e,c)
	return e:GetOwner()==c
end

-- 3. Half LP Gain calculation
function s.lpval(e,c)
	return math.floor(Duel.GetLP(e:GetHandlerPlayer())/2)
end

-- 4. Equipped Monster ATK Gain calculation
function s.atkfilter(c,ec)
	return c:GetEquipTarget()==ec
end
function s.eqatkval(e,c)
	local atk=0
	local g=Duel.GetMatchingCardGroup(s.atkfilter,e:GetHandlerPlayer(),LOCATION_SZONE,0,nil,c)
	for tc in aux.Next(g) do
		local catk=tc:GetTextAttack()
		if catk<0 then catk=0 end
		atk=atk+catk
	end
	return atk
-- 6. Special Summon Equipped Monster Logic
function s.spfilter(c,e,tp,ec)
	return c:GetEquipTarget()==ec and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp,c) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_SZONE,0,1,nil,e,tp,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_SZONE,0,1,1,nil,e,tp,c)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end