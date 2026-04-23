local s,id=GetID()
function s.initial_effect(c)
	-- Name treated as "Chaos Form"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetValue(21082832) 
	c:RegisterEffect(e0)

	-- Search Ritual on activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- Ritual Summon: Shuffle from GY
	local e2=Ritual.CreateProc({
		handler=c,
		lvtype=RITPROC_EQUAL,
		filter=s.ritfilter,
		location=LOCATION_HAND,
		matfilter=s.matfilter,
		extrafil=s.extrafil,
		extraop=s.extraop,
		stage2=s.stage2
	})
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	c:RegisterEffect(e2)
end

function s.ritfilter(c)
	return c:IsSetCard(0xcf) or c:IsSetCard(0x10cf) -- "Chaos" or "Black Luster Soldier"
end

function s.matfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) and c:IsAbleToDeck()
end

function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil)
end

function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	Duel.SendtoDeck(mg,nil,SEQ_DECKTOP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end

function s.stage2(mg,e,tp,eg,ep,ev,re,r,rp,tc)
	-- Apply bonus effects based on Type
	-- (Dragon: Attack wipe, Spellcaster: S/T Banish, Warrior: Double ATK)
end