React = require 'react'
_ = require 'underscore'
{Router, Route, IndexRoute, Link, browserHistory} = require 'react-router'
fetch$ = require 'kefir-fetch'

{ValidatedFormMixin} = require 'validated-form'

# Field definitions

email_field =
    name: 'email'
    type: 'email'
    icon: 'envelope'
    error_message: 'Please enter a valid email'

password_field =
    name: 'password'
    type: 'password'
    icon: 'key'
    error_message: 'Please enter a password'

confirm_password_field =
    name: 'confirm_password'
    type: 'password'
    icon: 'key'
    error_message: 'Confirm your password'

token_field =
    name: 'reset_token'
    type: 'hidden'
    error_message: 'No reset token'

Dispatcher =
    doSubmit: (url, data) ->
        fetch$ 'post', url, {body: data}

LoginMixin =

    showNext: (resp) ->
        next = @props.location.query.next || '/'
        window.location = next

    showSuccess: ->
        browserHistory.push {pathname: @props.location.pathname + '/success', query: @props.location.query}

    handleError: (resp) ->
        @setState {errors: resp.errors}

    onSubmit: (values) ->
        @submitted$ = Dispatcher.doSubmit @url, values
        @submitted$.onValue @handleResponse
        @submitted$.onError @handleError

LoginForm = React.createClass
    mixins: [ValidatedFormMixin, LoginMixin]

    url: '/login.json'

    fields:
        email: email_field
        password: password_field

    getInitialState: ->
        values:
            email: ''
            password: ''
        errors: {}
        loading: false

    handleResponse: (resp) ->
        if resp.errors?
            @handleError resp
        else
            @showNext()

    render: ->
        <div>
            <h3>Log in</h3>
            <form onSubmit=@trySubmit>
                {@renderField('email')}
                {@renderField('password')}
                <button type='submit' disabled={@state.loading}>
                    {if @state.loading then 'Logging in...' else 'Log in'}
                </button>
            </form>
        </div>

SignupForm = React.createClass
    mixins: [ValidatedFormMixin, LoginMixin]

    fields:
        email: email_field
        password: password_field

    url: '/signup.json'

    getInitialState: ->
        values:
            email: ''
            password: ''
        errors: {}
        loading: false

    handleResponse: (resp) ->
        if resp.errors?
            @handleError resp
        else
            @showNext()

    render: ->
        <div>
            <h3>Sign up</h3>
            <form onSubmit=@trySubmit>
                {@renderField('email')}
                {@renderField('password')}
                <button type='submit' disabled={@state.loading}>
                    {if @state.loading then 'Signing up...' else 'Sign up'}
                </button>
            </form>
        </div>

ForgotForm = React.createClass
    mixins: [ValidatedFormMixin, LoginMixin]
    fields:
        email: email_field

    url: '/forgot.json'

    getInitialState: ->
        values:
            email: ''
        errors: {}
        loading: false

    handleResponse: (resp) ->
        if resp.errors?
            @handleError resp
        else
            @showSuccess()

    render: ->

        <form onSubmit=@trySubmit>
            <h3>Forgot your password?</h3>
            {@renderField('email')}
            <button type='submit' disabled={@state.loading}>
                {if @state.loading then 'Processing...' else 'Reset password'}
            </button>
        </form>

ForgotSuccess = React.createClass
    render: ->
        <div className='center'>
            {if options.forgot_success_view
                options.forgot_success_view
            else
                <div>
                    <h3>Check your email!</h3>
                    <p>We sent you an email with instructions to reset your password.</p>
                </div>
            }
        </div>

ResetForm = React.createClass
    mixins: [ValidatedFormMixin, LoginMixin]
    fields:
        password: password_field
        confirm_password: confirm_password_field
        reset_token: token_field

    url: '/reset.json'

    getInitialState: ->
        values:
            password: ''
            confirm_password: ''
            reset_token: @props.params.reset_token || ''
        errors: {}
        loading: false

    handleResponse: (resp) ->
        if resp.errors?
            @handleError resp
        else
            @showSuccess()

    render: ->

        <form onSubmit=@trySubmit>
            <h3>Set your password</h3>
            {@renderField('password')}
            {@renderField('confirm_password')}
            <button type='submit' disabled={@state.loading}>
                {if @state.loading then 'Processing...' else 'Set password'}
            </button>
        </form>

ResetSuccess = React.createClass

    render: ->
        <div className='center'>
            {if options.success_view
                options.success_view
            else
                <div>
                    <h3>Successfully set your password</h3>
                    <div className='form-links'>
                        <Link to={pathname: "/login", query: @props.location.query}>Continue to login</Link>
                    </div>
                </div>
            }
        </div>

App = React.createClass
    getInitialState: ->
        active: 'login'

    render: ->
        console.log '[App.render]', @props

        path = @props.routes.slice(-1)[0].name
        if !path.length or path=='unknown' then path = 'login'

        links =
            login:
                <div className='form-links'>
                    {if !options.hide_forgot then <Link to={pathname: "/forgot", query: @props.location.query}>Forgot Password?</Link>}
                    {if !options.hide_signup then <Link to={pathname: "/signup", query: @props.location.query}>Don't have an account?</Link>}
                </div>
            signup:
                <div className='form-links'>
                    {if !options.hide_login then <Link to={pathname: "/login", query: @props.location.query}>Already have an account?</Link>}
                </div>
            forgot:
                <div className='form-links'>
                    {if !options.hide_login then <Link to={pathname: "/login", query: @props.location.query}>&laquo; Nevermind</Link>}
                    {if @props.has_signup then <Link to={pathname: "/signup", query: @props.location.query}>Don't have an account?</Link>}
                </div>
            reset: null

        <div id='login-module' className='section'>
            {@props.children}
            {links[path]}
        </div>

window.options = {}

setNext = (nextState, replace) ->
    next = nextState.location.pathname
    replace '/?next=' + next

LoginPage = (options) ->
    _.extend window.options, options
    routes =
        <Route path="/" component=App>
            <IndexRoute name="login" component=LoginForm />
            <Route path="login" name="login" component=LoginForm />
            <Route path="reset/:reset_token" name="reset" component=ResetForm />
            <Route path="reset/:reset_token/success" name="reset-success" component=ResetSuccess />
            <Route path="welcome/:reset_token" name="reset" component=ResetForm />
            <Route path="welcome/:reset_token/success" name="reset-success" component=ResetSuccess />
            {if !options.hide_signup then <Route path="signup" name="signup" component=SignupForm />}
            {if !options.hide_forgot then <Route path="forgot" name="forgot" component=ForgotForm />}
            {if !options.hide_forgot then <Route path="forgot/success" name="forgot-success" component=ForgotSuccess />}
            {options.extra_routes}
            <Route path="*" name="unknown" component=LoginForm onEnter=setNext />
        </Route>
    <Router routes=routes history=browserHistory />

module.exports = {
    LoginPage
    LoginForm
    SignupForm
    ForgotForm
    ResetForm
}