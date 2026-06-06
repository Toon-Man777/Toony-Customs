local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Set this card from hand to your Spell & Trap zone as a Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetTarget(s.set_target)
	e1:SetOperation(s.set_operation)
	c:RegisterEffect(e1)

	-- Effect 2: If this set card in the S&T zone is sent to the GY: Special Summon it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id) -- Hard once per turn on Effect 2
	e2:SetCondition(s.sp_condition)
	e2:SetTarget(s.sp_target)
	e2:SetOperation(s.sp_operation)
	c:RegisterEffect(e2)

	-- Effect 3: When Normal/Special Summoned: Set 1 "Toy" monster from hand OR if you control "Toy Box", Special Summon 1 level 4 or lower monster that mentions "Toy Box" from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,id+100) -- Hard once per turn on Effect 3
	e3:SetTarget(s.sum_target)
	e3:SetOperation(s.sum_operation)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end

-- Official Database Passcode IDs for Archetype Coordination
s.listed_names={6868} -- "Toy Box" standard card ID

-- Effect 1 Handlers (Hand-to-Spell Placement)
function s.set_target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.set_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 or not c:IsRelateToEffect(e) then return end
	-- Place face-down directly onto the field as a continuous/generic spell
	Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
	local e1=Effect.CreateEffect(c)
	e1:SetCode(EFFECT_CHANGE_TYPE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(TYPE_SPELL)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
	c:RegisterEffect(e1)
end

-- Effect 2 Handlers (GY Float Trigger)
function s.sp_condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Verifies the card was sent to the GY specifically while face-down (set) in the S&T zone
	return c:IsPreviousLocation(LOCATION_SZONE) and c:IsPreviousPosition(POS_FACEDOWN)
end
function s.sp_target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.sp_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Effect 3 Handlers (Summon Trigger Split)
function s.toybox_filter(c)
	return c:IsFaceup() and c:IsCode(6868) -- "Toy Box"
end
function s.setfilter(c)
	-- Filters for any monster containing "Toy" in its name that can place itself
	if not c:IsMonster() then return false end
	local name=c:GetOriginalName()
	local code=c:GetOriginalCode()
	return c:IsSetCard(0x1a4) or string.find(name or "","Toy")~=nil -- standard Toy matching
end
function s.spgyfilter(c,e,tp)
	-- Filters for Level 4 or lower monsters in the GY that mention "Toy Box"
	return c:IsLevelBelow(4) and c:IsListsName(6868) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sum_target(e,tp,eg,ep,ev,re,r,rp,chk)
	local has_toybox = Duel.IsExistingMatchingCard(s.toybox_filter,tp,LOCATION_ONFIELD,0,1,nil) -- Control "Toy Box" check
	local can_set = Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_HAND,0,1,nil) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	local can_spgy = has_toybox and Duel.IsExistingMatchingCard(s.spgyfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0

	if chk==0 then return can_set or can_spgy end
	
	-- Dynamically flags which operation branch is legally accessible for safety
	if can_spgy then
		e:SetLabel(1) -- GY Special Summon option active
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	else
		e:SetLabel(0) -- Hand Set option active
	end
end

function s.sum_operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local has_toybox = Duel.IsExistingMatchingCard(s.toybox_filter,tp,LOCATION_ONFIELD,0,1,nil)
	local can_set = Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_HAND,0,1,nil) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	local can_spgy = has_toybox and Duel.IsExistingMatchingCard(s.spgyfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0

	-- If you control Toy Box, choose whether to default to GY summon or Hand Setting
	local choice = 0
	if can_spgy and can_set then
		if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then choice = 1 end
	elseif can_spgy then
		choice = 1
	end

	if choice == 1 then
		-- Execute Branch B: Special Summon 1 Level 4 or lower from GY that mentions "Toy Box"
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spgyfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	else
		-- Execute Branch A: Set 1 "Toy" monster from your hand
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_HAND,0,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true)
			local e1=Effect.CreateEffect(c)
			e1:SetCode(EFFECT_CHANGE_TYPE)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(TYPE_SPELL)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TO_FIELD)
			tc:RegisterEffect(e1)
		end
	end
end