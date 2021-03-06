"""
$(TYPEDSIGNATURES)

Generate `ODESystem`, dependent variables, and parameters from an `ODEProblem`.
"""
function modelingtoolkitize(prob::DiffEqBase.ODEProblem)
    prob.f isa DiffEqBase.AbstractParameterizedFunction &&
                            return (prob.f.sys, prob.f.sys.states, prob.f.sys.ps)
    @parameters t
    vars = reshape([Variable(:x, i)(t) for i in eachindex(prob.u0)],size(prob.u0))
    params = prob.p isa DiffEqBase.NullParameters ? [] :
             reshape([Variable(:α,i)() for i in eachindex(prob.p)],size(prob.p))
    @derivatives D'~t

    rhs = [D(var) for var in vars]

    if DiffEqBase.isinplace(prob)
        lhs = similar(vars, Any)
        prob.f(lhs, vars, params, t)
    else
        lhs = prob.f(vars, params, t)
    end

    eqs = vcat([rhs[i] ~ lhs[i] for i in eachindex(prob.u0)]...)
    de = ODESystem(eqs,t,vec(vars),vec(params))

    de
end



"""
$(TYPEDSIGNATURES)

Generate `SDESystem`, dependent variables, and parameters from an `SDEProblem`.
"""
function modelingtoolkitize(prob::DiffEqBase.SDEProblem)
    prob.f isa DiffEqBase.AbstractParameterizedFunction &&
                            return (prob.f.sys, prob.f.sys.states, prob.f.sys.ps)
    @parameters t
    vars = reshape([Variable(:x, i)(t) for i in eachindex(prob.u0)],size(prob.u0))
    params = prob.p isa DiffEqBase.NullParameters ? [] :
             reshape([Variable(:α,i)() for i in eachindex(prob.p)],size(prob.p))
    @derivatives D'~t

    rhs = [D(var) for var in vars]

    if DiffEqBase.isinplace(prob)
        lhs = similar(vars, Any)
        prob.f(lhs, vars, params, t)

        if DiffEqBase.is_diagonal_noise(prob)
            neqs = similar(vars, Any)
            prob.g(neqs, vars, params, t)
        else
            neqs = similar(vars, Any, size(prob.noise_rate_prototype))
            prob.g(neqs, vars, params, t)
        end
    else
        lhs = prob.f(vars, params, t)
        if DiffEqBase.is_diagonal_noise(prob)
            neqs = prob.g(vars, params, t)
        else
            neqs = prob.g(vars, params, t)
        end
    end
    deqs = vcat([rhs[i] ~ lhs[i] for i in eachindex(prob.u0)]...)
    
    de = SDESystem(deqs,neqs,t,vec(vars),vec(params))

    de
end
