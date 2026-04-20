local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Add "Chaos Form" and/or 1 Ritual Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	-- Effect 2: Banish from GY to recycle and draw
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

s.listed_names={21082832} -- Chaos Form

-- Search Filter Logic
function s.thfilter1(c)
	return c:IsCode(21082832) and c:IsAbleToHand()
end
function s.thfilter2(c)
	return c:IsRitualMonster() and c:ListsCode(21082832) and c:IsAbleToHand()
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler()) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
		or Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	local g2=Duel.GetMatchingGroup(s.thfilter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
	if #g1==0 and #g2==0 then return end
	
	local sg=Group.CreateGroup()
	if #g1>0 and (#g2==0 or Duel.SelectYesNo(tp,aux.Stringid(id,2))) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local tc1=g1:Select(tp,1,1,nil)
		sg:Merge(tc1)
	end
	if #g2>0 and (#sg==0 or Duel.SelectYesNo(tp,aux.Stringid(id,3))) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local tc2=g2:Select(tp,1,1,nil)
		sg:Merge(tc2)
	end
	
	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- Draw/Recycle Logic
function s.drfilter(c)
	return (c:IsCode(21082832) or (c:IsSetCard(0xcf) and c:IsRitualMonster())) 
		and c:IsFaceup() and c:IsAbleToDeck()
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.drfilter(chkc) end
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) 
		and Duel.IsExistingTarget(s.drfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.drfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoDeck(tc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)>0 then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end