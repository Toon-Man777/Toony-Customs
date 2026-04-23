local s,id=GetID()
function s.initial_effect(c)
	-- Activation Effect: Excavate 5 and choose 1
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(0x4000+0x1+0x2+0x4+0x8) -- DECKDES+SPSUMMON+TOHAND+TOGRAVE+REMOVE
	e1:SetType(0x10000) -- EFFECT_TYPE_ACTIVATE
	e1:SetCode(0) -- EVENT_FREE_CHAIN
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Banished Effect: Target protection for "Cursed" monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(1+0x40) -- EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F
	e2:SetCode(1004) -- EVENT_REMOVE
	e2:SetProperty(0x10000) -- EFFECT_FLAG_DELAY
	e2:SetOperation(s.targetop)
	c:RegisterEffect(e2)
end

-- Filter for "Cursed" monsters using setcode 0x923
function s.cursed_filter(c)
	return c:IsSetCard(0x923) and c:IsFaceup()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,1,0)>=5 end
	Duel.SetOperationInfo(0,0x4000,nil,0,tp,5)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,1,0)<5 then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	if #g>0 then
		Duel.DisableShuffleCheck()
		
		-- Logic for the three choices
		local sg1=g:Filter(function(c) return c:IsType(0x1) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,nil)
		local sg2=g:Filter(function(c) return c:IsType(0x1) and c:IsAbleToHand() end,nil)
		local sg3=g:Filter(function(c) return c:IsType(0x2+0x4) and c:IsAbleToGrave() end,nil)
		
		local b1 = #sg1>0 and Duel.GetLocationCount(tp,4)>0
		local b2 = #sg2>0
		local b3 = #sg3>0
		
		local op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,0)}, -- Special Summon 1 Level 4 or lower
			{b2,aux.Stringid(id,1)}, -- Add 1 monster to hand
			{b3,aux.Stringid(id,2)}) -- Send 1 S/T to GY, then banish 1 from either GY
		
		local sel_card=nil
		if op==1 then
			sel_card=sg1:Select(tp,1,1,nil):GetFirst()
			Duel.SpecialSummon(sel_card,0,tp,tp,false,false,1)
		elseif op==2 then
			sel_card=sg2:Select(tp,1,1,nil):GetFirst()
			Duel.SendtoHand(sel_card,nil,64)
			Duel.ConfirmCards(1-tp,sel_card)
		elseif op==3 then
			sel_card=sg3:Select(tp,1,1,nil):GetFirst()
			if Duel.SendtoGrave(sel_card,64)>0 then
				Duel.Hint(3,tp,505) -- HINTMSG_REMOVE
				local bg=Duel.SelectMatchingCard(tp,nil,tp,16+16*65536,16+16*65536,1,1,nil)
				if #bg>0 then Duel.Remove(bg,0,64) end
			end
		end
		
		-- Remaining cards to the bottom of the deck
		if sel_card then g:RemoveCard(sel_card) end
		if #g>0 then
			Duel.SortDecktop(tp,tp,#g)
			for i=1,#g do
				local dg=Duel.GetDecktopGroup(tp,1)
				Duel.MoveSequence(dg:GetFirst(),1) -- 1 is SEQ_DECKBOTTOM
			end
		end
	end
end

function s.targetop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.cursed_filter,tp,4,0,nil)
	for tc in aux.Next(g) do
		-- Cannot be targeted by card effects until end of turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(1) -- EFFECT_TYPE_SINGLE
		e1:SetCode(160) -- EFFECT_CANNOT_BE_EFFECT_TARGET
		e1:SetValue(aux.tgoval)
		e1:SetReset(0x2000000+0x02) -- RESET_PHASE+PHASE_END
		tc:RegisterEffect(e1)
	end
end