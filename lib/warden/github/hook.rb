Warden::Manager.after_authentication do |user, auth, opts|
  scope = opts.fetch(:scope)
  strategy = auth.winning_strategies[scope]

  strategy.finalize_flow!  if strategy.class == Warden::GitHub::Strategy
end

Warden::Manager.after_set_user do |user, auth, opts|
  if user.is_a?(Warden::GitHub::User)
    session = auth.session(opts.fetch(:scope))
    user.memberships = session[:_memberships] ||= {}
  end
end
