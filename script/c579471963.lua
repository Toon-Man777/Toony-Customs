local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon Procedure
	c:EnableReviveLimit()
	-- Material formula: "Mokey Mokey King" + "Mokey Mokey" OR 4 "Mokey Mokey" monsters
	Fusion.AddProcMixRep(c,true,true,s.matfilter2,1,1,s.matfilter1)
	
	-- Custom material check function handling both combinations safely
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_FUSION_MATERIAL)
	e0:SetCondition(s.fuscon)
	e0:SetOperation(s.fusop)
	c:RegisterEffect(e0)

	-- Must first be Fusion Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(aux.fuslimit)
	c:RegisterEffect(e1)

	-- EFFECT 1: All battle damage involving "Mokey Mokey" is inflicted to your opponent
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_REFLECT_BATTLE_DAMAGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.damtg)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- EFFECT 2: Cannot be destroyed by your opponent's card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(aux.indoval)
	c:RegisterEffect(e3)

	-- EFFECT 3: Board Negation & ATK manipulation (Quick Effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(TIMING_MAIN_END+TIMINGS_CHECK_MONSTER,TIMING_MAIN_END+TIMINGS_CHECK_MONSTER)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.negcon)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)

	-- EFFECT 4: Floating effect if it leaves the field by an opponent's card effect
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e5:SetCode(EVENT_LEAVE_FIELD)
	e5:SetCountLimit(1,id+100)
	e5:SetCondition(s.spcon)
	e5:SetTarget(s.sptg)
	e5:SetOperation(s.spop)
	c:RegisterEffect(e5)
end

s.listed_names={27288416,130803864} -- "Mokey Mokey", "Mokey Mokey King"
s.listed_series={0x184}

-- Fusion Material Check Subroutines
function s.matfilter1(c)
	return c:IsCode(27288416) or c:IsSetCard(0x184)
end
function s.matfilter2(c)
	return c:IsCode(130803864) -- Updated to correct King code
end

function s.fuscon(e,g,gc,chkf)
	if g==nil then return true end
	if gc then return false end
	local tp=e:GetHandlerPlayer()
	
	-- Combination A: 1 Mokey Mokey King + 1 Mokey Mokey
	local g1=g:Filter(s.matfilter2,nil)
	local g2=g:Filter(s.matfilter1,nil)
	local comboA = #g1>0 and g2:IsExists(function(c) return not g1:Contains(c) end)

	-- Combination B: 4 Mokey Mokey monsters
	local comboB = g:FilterCount(s.matfilter1,nil)>=4

	return comboA or comboB
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
	local g=Duel.GetFusionMaterial(tp)
	local g1=g:Filter(s.matfilter2,nil)
	local g2=g:Filter(s.matfilter1,nil)
	
	local selectA = #g1>0 and g2:IsExists(function(c) return not g1:Contains(c) end)
	local selectB = g2:FilterCount(Card.IsCanBeFusionMaterial,nil,e:GetHandler())>=4
	
	local sg=Group.CreateGroup()
	if selectA and (not selectB or Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))==0) then
		-- Execute Combination A Selection
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local mat1=g1:Select(tp,1,1,nil)
		sg:Merge(mat1)
		g2:Remove(Card.IsCode,nil,130803864)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local mat2=g2:Select(tp,1,1,nil)
		sg:Merge(mat2)
	else
		-- Execute Combination B Selection
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local mat=g2:Select(tp,4,4,nil)
		sg:Merge(mat)
	end
	Duel.SetFusionMaterial(sg)
end

-- Battle Damage Reflection Targets
function s.damtg(e,c)
	return c:IsCode(27288416) or c:IsSetCard(0x184)
end

-- Quick Effect Activation Timing Windows
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() or Duel.IsBattlePhase()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatableMonster,tp,0,LOCATION_MZONE,1,nil) end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsNegatableMonster,tp,0,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_SET_ATTACK_FINAL)
		e3:SetValue(300)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e3)
	end
end

-- Floating Trigger Mechanics
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousControler(tp) and c:GetReasonPlayer()==1-tp and (r&REASON_EFFECT)~=0
end
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsLevelBelow(8) and c:IsSetCard(0x184)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end