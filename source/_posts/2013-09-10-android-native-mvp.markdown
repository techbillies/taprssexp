---
layout: post
title: "Android Development - Harnessing powers of MVP"
date: 2013-09-10 18:33
comments: true
---

As we set out to develop the native android app for [Ashoka Survey](https://thesurveys.org), discussions about how should the architecture pan out ensued. Literature on the internet was not promising and we had to come back to the drawing board for almost every hurdle we jumped through – setting up the IDE, prominent libraries that could come handy, better ways to do testing. After two repo reboots, we finally decided on these:

- IntelliJ Idea CE
- JUnit
- [Robolectric](https://github.com/robolectric/robolectric)
- [RoboGuice](https://github.com/roboguice/roboguice)
- [Mockito](https://code.google.com/p/mockito)
- [FEST](http://fest.easytesting.org/)

Maven dictated the basic skeleton to work out from. If you are not aware of dependency injection, do check out an [earlier post by us on RoboGuice](http://planet.nilenso.com/blog/2013/07/10/using-roboguice-to-inject-views-into-a-pojo/). We used [Android Async Http library](https://github.com/loopj/android-async-http) to deal with servicing network requests.

Once we had the project setup sorted out, we ventured into getting out a basic login screen.

### Architecture

Identifying boundaries is paramount for writing good tests. Our `LoginActivity` started out to do way too many things - talking to network boundary and manipulating the view along with it. Testing proved to be a challenge at this point. What we wanted was:

1. Check to see if a view layer could be extracted out from `Activity`.
2. Identify a service layer which deals with IO.
3. Identify an presenter which could orchestrate the above.

Basically, flesh out an MVP-ish architecture. If the view layer and service layer can be neatly segregated out from the `Activity` into the presenter, testing them is just a breeze.

![MVP](/images/mvp.png)

A peek into the [LoginActivity](https://github.com/nilenso/ashoka-survey-mobile-native/blob/4cc2acd7698771fe483fb43cc6f38c0092495d1c/src/main/java/com/infinitisuite/surveymobile/LoginActivity.java) reveals this.


```java
public class LoginActivity extends RoboActivity {

    @Inject LoginPresenter mPresenter;
    @InjectView(R.id.sign_in_button) Button mSignInButtonView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);
        mPresenter.onCreate();

        mSignInButtonView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mPresenter.attemptLogin();
            }
        });
    }
    ...
}
```

That's it! Everything else is being delegated to the presenter. Nice and clean.

So, let's look at the [LoginPresenter](https://github.com/nilenso/ashoka-survey-mobile-native/blob/4cc2acd7698771fe483fb43cc6f38c0092495d1c/src/main/java/com/infinitisuite/surveymobile/presenters/LoginPresenter.java).

```java
public class LoginPresenter {
    private IUserService userService;
    private ILoginView loginView;

    @Inject
    public LoginPresenter(IUserService userService, ILoginView loginView) {
        this.userService = userService;
        this.loginView = loginView;
    }
    ...
}
```
Presenter is injected with the [UserService](https://github.com/nilenso/ashoka-survey-mobile-native/blob/4cc2acd7698771fe483fb43cc6f38c0092495d1c/src/main/java/com/infinitisuite/surveymobile/services/UserService.java) and the [LoginView](https://github.com/nilenso/ashoka-survey-mobile-native/blob/4cc2acd7698771fe483fb43cc6f38c0092495d1c/src/main/java/com/infinitisuite/surveymobile/views/LoginView.java) which then acts more or less like a controller henceforth. If you notice carefully, the presenter speaks only to respective service and view interfaces. This helps in generating cheap mocks against which you can run your tests.

Let's have a look at [LoginPresenterTest](https://github.com/nilenso/ashoka-survey-mobile-native/blob/4cc2acd7698771fe483fb43cc6f38c0092495d1c/src/test/java/com/infinitisuite/surveymobile/presenters/LoginPresenterTest.java).

```java
public class LoginPresenterTest {

    private LoginPresenter presenter;
    private ILoginView loginViewMock;
    private UserServiceStub userService;

    @Before
    public void setUp() throws Exception {
        loginViewMock = mock(ILoginView.class);
        userService = new UserServiceStub();
        presenter = new LoginPresenter(userService, loginViewMock);
    }
    ...
    @Test
    public void shows_error_message_if_username_and_password_are_wrong() throws Exception {
        userService.setFailure();
        doReturn("foo@bar.com").when(loginViewMock).getEmail();
        doReturn("bar").when(loginViewMock).getPassword();
        presenter.attemptLogin();
        verify(loginViewMock, times(1)).showLoginError();
    }
    ...
}
```

The mock is setup and verified to see if the contract defined by `ILoginView` interface is invoked. It should be pointed out this is the farthest these tests could go and are not exactly end-to-end. You could just create implementation stubs out of this interface, not touching any view state, and still have the test passing. But having this view layer abstraction, makes it so painless to write presenter tests. We shoud have a combination of few end-to-end tests and a whole battery of these functional tests.

### Conclusion

We wanted to give MVP a go because android applications did not appear to have patterns set in stone. It still isn't clear if MVP would pan out well with complex views or is it justified to break view logic entirely out of `Activity`. This is very much a work in progress.

![Login Screen](http://cl.ly/image/131M1t0b1K2n/2013-09-09%2009.47.00.png)
