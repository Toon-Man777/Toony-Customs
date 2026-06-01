local s,id=GetID()
function s.initial_effect(c)
	-- Disable natural Synchro Summoning by forcing the check to always fail
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,0,0,nil,0,0,function() return false end)

	-- Must be Special Summoned by banishing 3 Synchro Monsters from field/GY while controlling a "Meklord Emperor"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.sprcon)
	e2:SetTarget(s.sprtg)
	e2:SetOperation(s.sprop)
	c:RegisterEffect(e2)

	-- 1. Continuous Effect: "Meklord" monsters you control are unaffected by opponent's activated monster effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.etarget)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- 2. Quick Effect: Once while face-up, look at Extra Decks, equip 1 Synchro to your monster, destroy weaker opponent's monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_EQUIP+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL) 
	e4:SetCondition(s.quickcon)
	e4:SetTarget(s.quicktg)
	e4:SetOperation(s.quickop)
	c:RegisterEffect(e4)
end

s.listed_series={0x13, 0x3013} -- Meklord, Meklord Emperor

-- Summoning Condition Filters
function s.empfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x3013)
end
function s.sprfilter(c)
	return c:IsType(TYPE_SYNCHRO) and c:IsAbleToRemoveAsCost() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingCardGroup(s.sprfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	return Duel.GetLocationCountFromEx(tp,tp,rg,c)>0
		and Duel.IsExistingMatchingCard(s.empfilter,tp,LOCATION_MZONE,0,1,nil)
		and aux.SelectUnselectGroup(rg,e,tp,3,3,aux.ChkfMMZ(1),0)
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local rg=Duel.GetMatchingCardGroup(s.sprfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local g=aux.SelectUnselectGroup(rg,e,tp,3,3,aux.ChkfMMZ(1),1,tp,HINT_SELECTMSG,HINTMSG_REMOVE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	g:DeleteWithCell()
end

-- 1. Monster Effect Immunity Logic
function s.etarget(e,c)
	return c:IsSetCard(0x13)
end
function s.efilter(e,re)
	return re:IsActiveType(TYPE_MONSTER) and re:GetOwnerPlayer()~=e:GetHandlerPlayer() and re:IsActivated()
end

-- 2. Extra Deck Peeking & Equip/Board Wipe Logic
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)==0
end
function s.mymonfilter(c)
	return c:IsFaceup()
end
function s.exsyncreq(c)
	return c:IsType(TYPE_SYNCHRO)
end
function s.quicktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.mymonfilter,tp,LOCATION_MZONE,0,1,nil)
		and (Duel.IsExistingMatchingCard(s.exsyncreq,tp,LOCATION_EXTRA,0,1,nil) 
			or Duel.IsExistingMatchingCard(s.exsyncreq,tp,0,LOCATION_EXTRA,1,nil)) end
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_EXTRA)
end
function s.quickop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	local g1=Duel.GetFieldGroup(tp,LOCATION_EXTRA,0)
	local g2=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
	if #g1>0 then Duel.ConfirmCards(tp,g1) end
	if #g2>0 then Duel.ConfirmCards(tp,g2) end
	
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	
	local ex_g=Duel.GetMatchingCardGroup(s.exsyncreq,tp,LOCATION_EXTRA,LOCATION_EXTRA,nil)
	if #ex_g==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local my_g=Duel.SelectMatchingCard(tp,s.mymonfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local eq_target=my_g:GetFirst()
	if not eq_target then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local ec_g=ex_g:Select(tp,1,1,nil)
	local ec=ec_g:GetFirst()
	
	if ec then
		if not Duel.Equip(tp,ec,eq_target) then return end
		
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(eq_target)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		ec:RegisterEffect(e1)
		
		local eq_atk=ec:GetTextAttack()
		if eq_atk<0 then eq_atk=0 end
		
		Duel.BreakEffect()
		
		local des_g=Duel.GetMatchingCardGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,eq_atk)
		if #des_g>0 then
			Duel.Destroy(des_g,REASON_EFFECT)
		end
	end
end
function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end
function s.desfilter(c,atk)
	return c:IsFaceup() and c:GetAttack()<atk
end