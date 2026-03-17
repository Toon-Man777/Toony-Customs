--Generation NEXT Firewall Dragon
local s,id=GetID()
function s.initial_effect(c)

--Synchro Summon
Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
c:EnableReviveLimit()

--ATK gain on Synchro Summon
local e1=Effect.CreateEffect(c)
e1:SetCategory(CATEGORY_ATKCHANGE)
e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e1:SetCode(EVENT_SPSUMMON_SUCCESS)
e1:SetProperty(EFFECT_FLAG_DELAY)
e1:SetCondition(s.atkcon)
e1:SetTarget(s.atktg)
e1:SetOperation(s.atkop)
c:RegisterEffect(e1)

--GY summon effect
local e2=Effect.CreateEffect(c)
e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
e2:SetType(EFFECT_TYPE_IGNITION)
e2:SetRange(LOCATION_GRAVE)
e2:SetCountLimit(1,id)
e2:SetCost(aux.bfgcost)
e2:SetTarget(s.sptg)
e2:SetOperation(s.spop)
c:RegisterEffect(e2)

--Negate effect
local e3=Effect.CreateEffect(c)
e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
e3:SetType(EFFECT_TYPE_QUICK_O)
e3:SetCode(EVENT_CHAINING)
e3:SetRange(LOCATION_MZONE)
e3:SetCountLimit(1,id+100)
e3:SetCondition(s.negcon)
e3:SetCost(s.negcost)
e3:SetTarget(s.negtg)
e3:SetOperation(s.negop)
c:RegisterEffect(e3)

end

--Check Synchro Summon
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

--Target Link Monster
function s.atkfilter(c)
return c:IsType(TYPE_LINK) and c:IsAbleToRemove()
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return Duel.IsExistingTarget(s.atkfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil) end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
local g=Duel.SelectTarget(tp,s.atkfilter,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,e:GetHandler(),1,0,0)
end

--ATK gain operation
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
local c=e:GetHandler()
local tc=Duel.GetFirstTarget()
if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
local atk=tc:GetLink()*500
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetValue(atk)
e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
c:RegisterEffect(e1)
end
end

--Cyberse Link filter
function s.spfilter(c,e,tp)
return c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_LINK)
and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then
return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
end
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
if #g>0 then
Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
end
end

--Negate condition
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
return Duel.IsChainNegatable(ev)
end

--Lose 500 ATK cost
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
local c=e:GetHandler()
if chk==0 then return c:GetAttack()>=500 end
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetValue(-500)
e1:SetReset(RESET_EVENT+RESETS_STANDARD)
c:RegisterEffect(e1)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
if chk==0 then return true end
Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
if re:GetHandler():IsDestructable() then
Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
Duel.Destroy(eg,REASON_EFFECT)
end
end