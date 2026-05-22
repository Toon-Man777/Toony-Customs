local s,id=GetID()
function s.initial_effect(c)
	-- 1. Activate: Excavate 5 cards and choose 1 of 3 bullet effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- 2. When banished: Protect "Cursed" card effects from your own monster effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,id+1)
	e2:SetOperation(s.protop)
	c:RegisterEffect(e2)
end

-- Excavation targets and check functions
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,PLAYER_ALL,LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	Duel.BreakEffect()
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	if #g==0 then return end
	
	-- Evaluate legal choices based on what was excavated
	local b1=g:IsExists(Card.IsLevelBelow,1,nil,4) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local b2=g:IsExists(Card.IsType,1,nil,TYPE_MONSTER) and g:IsExists(Card.IsAbleToHand,1,nil)
	local b3=g:IsExists(Card.IsType,1,nil,TYPE_SPELL+TYPE_TRAP) and Duel.IsExistingMatchingCard(Card.IsAbleToBanish,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil)

	-- Prompt player choice based on available legal options
	local op=Duel.SelectEffect(tp,
		{b1, aux.Stringid(id,1)}, -- Special Summon
		{b2, aux.Stringid(id,2)}, -- Add to Hand
		{b3, aux.Stringid(id,3)}) -- Send to GY + Banish GY

	if op==1 then
		-- Bullet 1: Special Summon 1 Level 4 or lower monster
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:FilterSelect(tp,Card.IsLevelBelow,1,1,nil,4)
		if #sg>0 then
			Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
			g:RemoveCard(sg:GetFirst())
		end
		
	elseif op==2 then
		-- Bullet 2: Add 1 monster to hand
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:FilterSelect(tp,Card.IsType,1,1,nil,TYPE_MONSTER)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			g:RemoveCard(sg:GetFirst())
		end
		
	elseif op==3 then
		-- Bullet 3: Send 1 Spell/Trap to GY, then banish 1 card from either GY
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:FilterSelect(tp,Card.IsType,1,1,nil,TYPE_SPELL+TYPE_TRAP)
		if #sg>0 then
			local tc=sg:GetFirst()
			if Duel.SendtoGrave(tc,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_GRAVE) then
				g:RemoveCard(tc)
				-- Put remainder on bottom BEFORE performing the next mandatory action
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
				local rg=g:Select(tp,0,5,nil)
				if #rg>0 then
					Duel.SortDecktop(tp,tp,#rg)
					for i=1,#rg do
						local dc=Duel.GetDecktopGroup(tp,1):GetFirst()
						Duel.MoveSequence(dc,SEQ_DECKBOTTOM)
					end
				end
				g:Clear() -- Cleared so double bottom-deck script segment doesn't duplicate
				
				-- Perform the required banish from either GY
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local bg=Duel.SelectMatchingCard(tp,Card.IsAbleToBanish,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
				if #bg>0 then
					Duel.Remove(bg,POS_FACEUP,REASON_EFFECT)
				end
			end
		end
	end

	-- Place the remaining unchosen cards on the bottom of the deck (For Bullet 1 & 2 operations)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local rg=g:Select(tp,0,5,nil)
		if #rg>0 then
			Duel.SortDecktop(tp,tp,#rg)
			for i=1,#rg do
				local dc=Duel.GetDecktopGroup(tp,1):GetFirst()
				Duel.MoveSequence(dc,SEQ_DECKBOTTOM)
			end
		end
	end
end

-- Banished effect: Protection handler
function s.protop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- 1. Protect card effects from destruction by your own monster effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetTargetRange(LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_HAND,0)
	e1:SetTarget(s.protg)
	e1:SetValue(s.indval)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.protg(e,c)
	-- Protects any card that belongs to your "Cursed" (0x923) archetype
	return c:IsSetCard(0x923)
end

function s.indval(e,re,rp)
	-- Checks if the source trying to destroy it is a monster effect (TYPE_MONSTER) controlled by you (rp == e:GetHandlerPlayer())
	return (re:GetHandler():IsType(TYPE_MONSTER)) and rp==e:GetHandlerPlayer()
end