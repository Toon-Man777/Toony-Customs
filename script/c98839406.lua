local s,id=GetID()
function s.initial_effect(c)
	-- Effect when banished
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DECKDES)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_REMOVE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

s.listed_series={0x923} -- Cursed archetype
s.listed_names={id} -- Refers to "Cursed Star Crimson Eclipse"

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsSetCard(0x923) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsSetCard,tp,LOCATION_MZONE,0,1,nil,0x923) 
		and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsSetCard,tp,LOCATION_MZONE,0,1,1,nil,0x923)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	-- Grant protection to targeted "Cursed" monster
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e1:SetValue(aux.tgoval)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end

	-- Reveal Top 5 cards
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	local g=Duel.GetDecktopGroup(tp,5)
	Duel.ConfirmCards(tp,g)
	Duel.ConfirmCards(1-tp,g)

	-- Branching logic for the 3 choices
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and g:IsExists(Card.IsLevelBelow,1,nil,4)
	local b2=g:IsExists(Card.IsMonster,1,nil)
	local b3=g:IsExists(Card.IsCode,1,nil,id) -- Checks for "Cursed Star Crimson Eclipse"

	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)}, -- Special Summon Level 4 or lower
		{b2,aux.Stringid(id,2)}, -- Add 1 Monster to hand
		{b3,aux.Stringid(id,3)}) -- Add this card to hand, others to GY

	if op==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:FilterSelect(tp,Card.IsLevelBelow,1,1,nil,4)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
		g:Sub(sg)
		Duel.SortDeckbottom(tp,tp,#g)
	elseif op==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:FilterSelect(tp,Card.IsMonster,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
		g:Sub(sg)
		Duel.SortDecktop(tp,tp,#g)
	elseif op==3 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:FilterSelect(tp,Card.IsCode,1,1,nil,id)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
		g:Sub(sg)
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end