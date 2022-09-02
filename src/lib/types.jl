# @doc raw"""
#     Spin()

# The set ``\left\lbrace{}{-1, 1}\right\rbrace{}``.
# """ struct Spin <: MOI.AbstractScalarSet end

# function MOIU._to_string(options::MOIU._PrintOptions, ::Anneal.Spin)
#     return string(MOIU._to_string(options, in), " {-1, 1}")
# end

# function MOIU._to_string(::MOIU._PrintOptions{MIME"text/latex"}, ::Anneal.Spin)
#     return raw"\in \left\lbrace{}{-1, 1}\right\rbrace{}"
# end

# ~ Adding a new variable set is way harder: `_single_variable_flag` looks crazy 🤙