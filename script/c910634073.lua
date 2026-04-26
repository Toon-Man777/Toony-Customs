local s,id=GetID()
function s.initial_effect(c)
	-- Equip Procedure
	aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(function(c) return not c:IsSetCard(0x25) end))

	-- Must attack and cannot be used as Ritual Tribute
	local e1=Effect.CreateEffect(c)
	e1:SetType(16) -- EFFECT_TYPE_FIELD
	e1:SetCode(13) -- EFFECT_MUST_ATTACK
	e1:SetRange(512) -- LOCATION_SZONE
	e1:SetTargetRange(4,4)
	e1:SetTarget(s.eqtg)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(16)
	e2:SetCode(63) -- EFFECT_UNRELEASABLE_SUM
	e2:SetRange(512)
	e2:SetTargetRange(4,4)
	e2:SetTarget(s.eqtg)
	e2:SetValue(function(e,c) return c:IsType(0x80) end)
	c:RegisterEffect(e2)

	-- Material Restrictions: Fusion, Synchro, Xyz, Link
	local codes={60,62,64,61,65} 
	for _,code in ipairs(codes) do
		local e3=Effect.CreateEffect(c)
		e3:SetType(1)
		e3:SetCode(code)
		e3:SetProperty(0x400)
		e3:SetValue(1)
		c:RegisterEffect(e3)
	end

	-- Dice Roll and Effect Activation
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(0x400000) -- CATEGORY_DICE
	e4:SetType(4) -- EFFECT_TYPE_IGNITION
	e4:SetRange(512)
	e4:SetCountLimit(1)
	e4:SetTarget(s.dicetg)
	e4:SetOperation(s.diceop)
	c:RegisterEffect(e4)
end

function s.eqtg(e,c)
	return c==e:GetHandler():GetEquipTarget()
end

function s.dicetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,0x400000,nil,0,tp,1)
end

function s.diceop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- Declare Type and Roll
	local opt=Duel.AnnounceType(tp)
	local dc=Duel.TossDice(tp,1)
	c:RegisterFlagEffect(id,0x1fe0000,0,1,dc)
	e:SetLabel(opt,dc)

	local ec=c:GetEquipTarget()
	if ec then
		-- Multi-attack (Roll value)
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(140) -- EFFECT_EXTRA_ATTACK
		e1:SetCondition(s.chaincon)
		e1:SetValue(dc-1)
		e1:SetReset(0x1fe0000)
		ec:RegisterEffect(e1)
		
		-- Piercing Damage
		local e2=Effect.CreateEffect(c)
		e2:SetType(1)
		e2:SetCode(113) -- EFFECT_PIERCE
		e2:SetCondition(s.chaincon)
		e2:SetReset(0x1fe0000)
		ec:RegisterEffect(e2)
	end

	-- Opponent Reactive Mill
	local e3=Effect.CreateEffect(c)
	e3:SetType(16)
	e3:SetCode(4101) -- EVENT_CHAIN_SOLVING
	e3:SetRange(512)
	e3:SetLabel(opt,dc)
	e3:SetCondition(s.millcon)
	e3:SetOperation(s.millop)
	e3:SetReset(0x1fe0000)
	c:RegisterEffect(e3)
end

-- Condition: Control "Poison Chain" (33302407) or "Iron Chain" (0x25)
function s.chaincon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x25) or c:IsCode(33302407) end,tp,4,0,1,nil)
end

function s.millcon(e,tp,eg,ep,ev,re,r,rp)
	local opt,dc = e:GetLabel()
	local ec = e:GetHandler():GetEquipTarget()
	if not ec or rp==tp then return false end
	
	-- Declared type match
	local type_match = (opt==0 and re:IsActiveType(0x1)) or (opt==1 and re:IsActiveType(0x2)) or (opt==2 and re:IsActiveType(0x4))
	-- ATK/DEF modified + No face-up non-"Iron Chain"
	local stat_mod = ec:GetAttack()~=ec:GetBaseAttack() or ec:GetDefense()~=ec:GetBaseDefense()
	local only_chains = not Duel.IsExistingMatchingCard(function(c) return not c:IsSetCard(0x25) end,tp,4,0,1,ec)
	
	return type_match and stat_mod and only_chains
end

function s.millop(e,tp,eg,ep,ev,re,r,rp)
	local _,dc = e:GetLabel()
	-- Send top of Deck equal to roll
	Duel.DiscardDeck(1-tp,dc,64)
	-- Lock GY effects for the phase
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(16)
	e1:SetCode(452) -- EFFECT_CANNOT_ACTIVATE
	e1:SetProperty(0x4000000)
	e1:SetTargetRange(0,1)
	e1:SetValue(function(e,re,tp) return re:GetActivateLocation()==16 end)
	e1:SetReset(0x2000000+0x08)
	Duel.RegisterEffect(e1,tp)
end