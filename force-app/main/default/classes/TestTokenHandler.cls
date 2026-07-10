public class TestTokenHandler extends Auth.Oauth2TokenExchangeHandler {

    public Auth.UserData getUserForTokenSubject(
        Auth.TokenValidationContext context
    ) {
        Auth.UserData user = new Auth.UserData();

        user.username = 'testuser@example.com';
        user.email = 'testuser@example.com';
        user.lastName = 'Test';

        return user;
    }
}