local s,id=GetID()
function s.initial_effect(c)
	-- Excavate 5 and choose an effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DECKDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	-- Protection effect when banished
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_BANISHED)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.protg)
	e2:SetOperation(s.proop)
	c:RegisterEffect(e2)
end

-- Archetype: Cursed (Custom setcode assumed as 0x5b3)
s.listed_series={0x5b3}

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	if #g>0 then
		Duel.DisableShuffleCheck()
		-- Determine valid effects based on excavated cards
		local b1=g:IsExists(function(c) return c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,1,nil) 
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		local b2=g:IsExists(Card.IsMonster,1,nil) and g:IsExists(Card.IsAbleToHand,1,nil)
		local b3=g:IsExists(Card.IsCode,1,nil,id)
		
		local op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,2)}, -- Special Summon
			{b2,aux.Stringid(id,3)}, -- Add 1 Monster
			{b3,aux.Stringid(id,4)}) -- Add copy of itself
		
		if op==1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=g:FilterSelect(tp,function(c) return c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end,1,1,nil)
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
			g:RemoveCard(sg:GetFirst())
			Duel.SortDecktop(tp,tp,#g)
		elseif op==2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=g:FilterSelect(tp,Card.IsMonster,1,1,nil)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			g:RemoveCard(sg:GetFirst())
			Duel.SortDecktop(tp,tp,#g)
		elseif op==3 then
			local sg=g:Filter(Card.IsCode,nil,id)
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			g:Sub(sg)
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
	end
end

-- Target "Cursed" Monster when banished
function s.protg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsSetCard(0x5b3) end
	if chk==0 then return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsSetCard,0x5b3),tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsSetCard,0x5b3),tp,LOCATION_MZONE,0,1,1,nil)
end

function s.proop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- Cannot be targeted by opponent's effects
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e1:SetValue(aux.tgoval)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end