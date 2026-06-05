local s,id=GetID()
function s.initial_effect(c)
	-- Must be Special Summoned from Extra Deck (Cannot be Synchro Summoned)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(aux.FALSE)
	c:RegisterEffect(e1)

	-- Special Summon Procedure: Banish 3 Synchro Monsters from field/GY while controlling a "Meklord Emperor"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	-- 1. Continuous Effect: "Meklord" monsters you control are unaffected by opponent's activated monster effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x13)) -- "Meklord" archetype
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- 2. Quick Effect: Look at Extra Decks, equip 1 Synchro to your monster, destroy weaker opponent monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_EQUIP+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUIVER+EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	-- "Once while face-up on the field" restriction
	e4:SetCountLimit(1,id,EFFECT_COUNT_CODE_SINGLE)
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)
end

s.listed_series={0x13, 0x3013} -- Meklord, Meklord Emperor

-- Special Summon Procedure Condition Handlers
function s.empfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x3013) -- "Meklord Emperor"
end
function s.matfilter(c)
	return c:IsType(TYPE_SYNCHRO) and (c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_GRAVE)) and c:IsAbleToRemoveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,nil)
	return Duel.IsExistingMatchingCard(s.empfilter,tp,LOCATION_MZONE,0,1,nil)
		and aux.SelectUnselectGroup(rg,e,tp,3,3,aux.ChkfMMZ(1),0)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,nil)
	local g=aux.SelectUnselectGroup(rg,e,tp,3,3,aux.ChkfMMZ(1),1,tp,HINTMSG_REMOVE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	g:DeleteLeaveEvent()
end

-- 1. Unaffected by Opponent Activated Monster Effects Filter
function s.efilter(e,re)
	return re:GetOwnerPlayer()==1-e:GetHandlerPlayer() and re:IsActiveType(TYPE_MONSTER) and re:IsActivated()
end

-- 2. Look, Equip, and Wipe Logic
function s.mymonfilter(c)
	return c:IsFaceup()
end
function s.exsynfilter(c)
	return c:IsType(TYPE_SYNCHRO)
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.mymonfilter,tp,LOCATION_MZONE,0,1,nil)
			and (Duel.IsExistingMatchingCard(s.exsynfilter,tp,LOCATION_EXTRA,0,1,nil) 
				or Duel.IsExistingMatchingCard(s.exsynfilter,tp,0,LOCATION_EXTRA,1,nil))
	end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,2,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,1-tp,LOCATION_MZONE)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 1. Look at both Extra Decks
	local g1=Duel.GetFieldGroup(tp,LOCATION_EXTRA,0)
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
	if #g1>0 then Duel.ConfirmCards(tp,g1) end
	if #g2>0 then Duel.ConfirmCards(tp,g2) end

	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	-- 2. Target 1 monster you control to receive the equip
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=Duel.SelectMatchingCard(tp,s.mymonfilter,tp,LOCATION_MZONE,0,1,1,nil):GetFirst()
	if not tc then return end

	-- 3. Select 1 Synchro Monster from either Extra Deck
	local exg=Duel.GetMatchingGroup(s.exsynfilter,tp,LOCATION_EXTRA,LOCATION_EXTRA,nil)
	if #exg==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local ec=exg:Select(tp,1,1,nil):GetFirst()
	if ec then
		-- Perform Equip
		if not Duel.Equip(tp,ec,tc) then return end
		
		-- Equip Logic Rules setup
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(tc)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		ec:RegisterEffect(e1)
		
		-- 4. Destroy opponent's monsters with less ATK than the equipped card
		local atk=ec:GetTextAttack()
		if atk<0 then atk=0 end -- Handles undefined or ? ATK values cleanly
		
		local dg=Duel.GetMatchingGroup(Card.IsAttackLessThan,tp,0,LOCATION_MZONE,nil,atk)
		if #dg>0 then
			Duel.BreakEffect()
			Duel.Destroy(dg,REASON_EFFECT)
		end
	end
end
function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end