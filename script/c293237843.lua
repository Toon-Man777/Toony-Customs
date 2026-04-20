local s,id=GetID()
function s.initial_effect(c)
	-- Treated as "Chaos Form"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetValue(21082832) -- ID of Chaos Form
	c:RegisterEffect(e0)

	-- Activation: Search 1 Ritual Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Effect 2: Ritual Summon "Chaos" or "BLS"
	-- Materials: Tribute (Hand/Field) or Shuffle (GY LIGHT/DARK)
	local e2=Ritual.CreateProc({
		handler=c,
		lvtype=RITPROC_EQUAL,
		filter=s.ritfilter,
		matfilter=s.matfilter,
		extrafil=s.extrafil,
		extraop=s.extraop,
		location=LOCATION_HAND,
		forcedselection=s.forcedselection
	})
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	c:RegisterEffect(e2)

	-- Effect 3: Grant Effects to Ritual Monsters
	-- Dragon: Board Wipe on Attack
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.granttg)
	e3:SetValue(s.grantval)
	c:RegisterEffect(e3)
end

-- Archetypes
s.listed_names={21082832} -- Chaos Form
s.listed_series={0xcf, 0x10cf} -- Chaos, Black Luster Soldier

-- Activation Search
function s.thfilter(c)
	return c:IsRitualMonster() and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end

-- Ritual Summon Logic
function s.ritfilter(c)
	return (c:IsSetCard(0xcf) or c:IsSetCard(0x10cf)) and c:IsRitualMonster()
end
function s.matfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and c:IsAbleToDeck()
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil)
end
function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	local tg=mg:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	if #tg>0 then
		Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
end

-- Granting Effects logic
function s.granttg(e,c)
	return c:IsRitualMonster() and c:IsFaceup()
end
function s.grantval(e,c)
	-- Dragon Effect
	if c:IsRace(RACE_DRAGON) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,2))
		e1:SetCategory(CATEGORY_DESTROY)
		e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
		e1:SetCode(EVENT_ATTACK_ANNOUNCE)
		e1:SetTarget(s.destg)
		e1:SetOperation(s.desop)
		c:RegisterEffect(e1,true)
	end
	-- Spellcaster Effect
	if c:IsRace(RACE_SPELLCASTER) then
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetDescription(aux.Stringid(id,3))
		e2:SetCategory(CATEGORY_REMOVE)
		e2:SetType(EFFECT_TYPE_IGNITION)
		e2:SetRange(LOCATION_MZONE)
		e2:SetCountLimit(1)
		e2:SetTarget(s.remtg)
		e2:SetOperation(s.remop)
		c:RegisterEffect(e2,true)
	end
	-- Warrior Effect
	if c:IsRace(RACE_WARRIOR) then
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
		e3:SetCode(EVENT_BATTLE_CONFIRM)
		e3:SetOperation(s.atkop)
		c:RegisterEffect(e3,true)
	end
end

-- Dragon: Destroy all other monsters
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler()) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,LOCATION_MZONE,e:GetHandler())
	Duel.Destroy(g,REASON_EFFECT)
end

-- Spellcaster: Banish Spells/Traps
function s.remtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
	local count=Duel.GetMatchingGroupCount(Card.IsRitualMonster,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,count,nil,TYPE_SPELL+TYPE_TRAP)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end
function s.remop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- Warrior: Double ATK
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(c:GetAttack()*2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end