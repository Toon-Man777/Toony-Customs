local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon materials: "Meklord Emperor Wisel" + 1+ non-Tuner Machine monsters
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,s.tunerfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)

	-- 1. Custom Summon Rule: Treat 1 "Meklord Emperor Wisel" you control as a Tuner
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

	-- 3. Continuous Effect: Gains ATK equal to the combined ATK of monsters equipped by its own effect
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	-- 4. Continuous Effect: Can make up to 2 attacks on monsters during each Battle Phase
	-- (Fixed the broken EFFECT_MONSTER_NOTARGET_BATTLE engine crash here)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_ATTACK_MONSTER_ONLY)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e5:SetValue(1)
	c:RegisterEffect(e5)

	-- 5. Quick Effect: Once per turn, negate a Spell activation and destroy it
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_CHAINING)
	e6:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_COND)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetCondition(s.negcon)
	e6:SetTarget(s.negtg)
	e6:SetOperation(s.negop)
	c:RegisterEffect(e6)
end

s.listed_names={68140974} -- Meklord Emperor Wisel

function s.tunerfilter(c,scard,sumtype,tp)
	return c:IsCode(68140974) and c:IsType(TYPE_TUNER,scard,sumtype,tp)
end
function s.customtunerfilter(c,scard,sumtype,tp)
	return c:IsCode(68140974) and c:IsFaceup()
end
function s.synctg(e,tg,ntg,sg,lv,sc,tp)
	return Synchro.ConditionMinMax(tg,ntg,sg,lv,sc,tp,s.customtunerfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)
end
function s.syncop(e,tp,eg,ep,ev,re,r,rp,tg,ntg,sg,lv,sc)
	return Synchro.OperationMinMax(tg,ntg,sg,lv,sc,tp,s.customtunerfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)
end
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
function s.atkfilter(c,ec)
	return c:GetEquipTarget()==ec
end
function s.atkval(e,c)
	local atk=0
	local g=Duel.GetMatchingGroup(s.atkfilter,e:GetHandlerPlayer(),LOCATION_SZONE,0,nil,c)
	for tc in aux.Next(g) do
		local catk=tc:GetTextAttack()
		if catk<0 then catk=0 end
		atk=atk+catk
	end
	return atk
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_SPELL) and Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end