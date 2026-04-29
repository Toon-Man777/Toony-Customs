local s,id=GetID()
function s.initial_effect(c)
	-- Equip to non-"Iron Chain"
	aux.AddEquipProcedure(c,nil,function(c) return not c:IsSetCard(0x25) end)
	-- No Material/Tribute
	local codes={60,61,62,63,64,65}
	for _,code in ipairs(codes) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(1)
		e1:SetCode(code)
		e1:SetValue(1)
		c:RegisterEffect(e1)
	end
	-- Dice Roll Ignition
	local e2=Effect.CreateEffect(c)
	e2:SetType(4)
	e2:SetRange(512)
	e2:SetCountLimit(1)
	e2:SetOperation(s.diceop)
	c:RegisterEffect(e2)
end
function s.diceop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local opt=Duel.AnnounceType(tp)
	local dc=Duel.TossDice(tp,1)
	-- Multi-attack + Pierce Condition
	local ec=c:GetEquipTarget()
	if ec then
		local con=function(e) return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x25) or c:IsCode(33302407) end,e:GetHandlerPlayer(),4,0,1,nil) end
		local e1=Effect.CreateEffect(c)
		e1:SetType(1):SetCode(140):SetCondition(con):SetValue(dc-1):SetReset(0x1fe0000)
		ec:RegisterEffect(e1)
		local e2=e1:Clone():SetCode(113):SetValue(1)
		ec:RegisterEffect(e2)
	end
	-- Reactive Mill
	local e3=Effect.CreateEffect(c)
	e3:SetType(16):SetCode(4101):SetRange(512):SetLabel(opt,dc)
	e3:SetCondition(s.millcon):SetOperation(s.millop):SetReset(0x1fe0000)
	c:RegisterEffect(e3)
end
function s.millcon(e,tp,eg,ep,ev,re,r,rp)
	local opt,dc=e:GetLabel()
	local ec=e:GetHandler():GetEquipTarget()
	local type_match=(opt==0 and re:IsActiveType(1)) or (opt==1 and re:IsActiveType(2)) or (opt==2 and re:IsActiveType(4))
	return rp~=tp and type_match and ec and (ec:GetAttack()~=ec:GetBaseAttack())
end
function s.millop(e,tp)
	local _,dc=e:GetLabel()
	Duel.DiscardDeck(1-tp,dc,64)
end