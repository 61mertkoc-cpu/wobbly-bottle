package com.wobblybottle.game;

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.FrameLayout;

public class MainActivity extends Activity {
    private GameView gameView;
    private EditText nameInput;
    private ConnectivityManager connectivityManager;
    private ConnectivityManager.NetworkCallback networkCallback;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        hideSystemBars();

        FrameLayout root = new FrameLayout(this);
        gameView = new GameView(this);
        gameView.setScreenListener(this::updateInputVisibility);
        root.addView(gameView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        nameInput = new EditText(this);
        nameInput.setSingleLine(true);
        nameInput.setHint("Enter player name...");
        nameInput.setHintTextColor(Color.rgb(78, 178, 190));
        nameInput.setTextColor(Color.WHITE);
        nameInput.setTextSize(18);
        nameInput.setPadding(24, 0, 18, 0);
        nameInput.setGravity(Gravity.CENTER_VERTICAL);
        GradientDrawable inputBg = new GradientDrawable();
        inputBg.setColor(Color.rgb(5, 23, 37));
        inputBg.setCornerRadius(20);
        inputBg.setStroke(2, Color.rgb(0, 242, 254));
        nameInput.setBackground(inputBg);

        FrameLayout.LayoutParams inputParams = new FrameLayout.LayoutParams(1, 1);
        root.addView(nameInput, inputParams);
        setContentView(root);

        gameView.setNameProvider(new GameView.NameProvider() {
            @Override public String getName() { return nameInput.getText().toString().trim(); }
            @Override public void clearName() { nameInput.setText(""); }
            @Override public void focusName() {
                nameInput.requestFocus();
                ((InputMethodManager)getSystemService(INPUT_METHOD_SERVICE))
                        .showSoftInput(nameInput, InputMethodManager.SHOW_IMPLICIT);
            }
        });

        root.post(this::positionInput);
        registerNetworkMonitor();
    }

    private void positionInput() {
        int width = gameView.getWidth();
        int height = gameView.getHeight();
        if (width == 0 || height == 0) return;
        float scale = Math.min(width / 1080f, height / 1920f);
        float left = (width - 1080f * scale) / 2f;
        float top = (height - 1920f * scale) / 2f;
        FrameLayout.LayoutParams p = (FrameLayout.LayoutParams) nameInput.getLayoutParams();
        p.width = Math.round(480 * scale);
        p.height = Math.round(110 * scale);
        p.leftMargin = Math.round(left + 104 * scale);
        p.topMargin = Math.round(top + 375 * scale);
        nameInput.setLayoutParams(p);
        updateInputVisibility(gameView.getScreen());
    }

    private void updateInputVisibility(int screen) {
        nameInput.setVisibility(screen == GameView.SCREEN_SETUP ? View.VISIBLE : View.GONE);
        if (screen != GameView.SCREEN_SETUP) {
            nameInput.clearFocus();
            ((InputMethodManager)getSystemService(INPUT_METHOD_SERVICE))
                    .hideSoftInputFromWindow(nameInput.getWindowToken(), 0);
        }
    }

    private void registerNetworkMonitor() {
        connectivityManager = (ConnectivityManager)getSystemService(Context.CONNECTIVITY_SERVICE);
        networkCallback = new ConnectivityManager.NetworkCallback() {
            @Override public void onAvailable(Network network) { refreshNetworkState(); }
            @Override public void onLost(Network network) { refreshNetworkState(); }
            @Override public void onCapabilitiesChanged(Network n, NetworkCapabilities c) { refreshNetworkState(); }
        };
        NetworkRequest request = new NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build();
        connectivityManager.registerNetworkCallback(request, networkCallback);
        refreshNetworkState();
    }

    private void refreshNetworkState() {
        Network active = connectivityManager.getActiveNetwork();
        NetworkCapabilities caps = active == null ? null : connectivityManager.getNetworkCapabilities(active);
        boolean online = caps != null
                && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED);
        runOnUiThread(() -> gameView.setOnline(online));
    }

    private void hideSystemBars() {
        View decor = getWindow().getDecorView();
        if (android.os.Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController controller = decor.getWindowInsetsController();
            if (controller != null) {
                controller.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                controller.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        }
        decor.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    }

    @Override protected void onResume() {
        super.onResume();
        hideSystemBars();
        if (gameView != null) gameView.resumeAnimation();
    }

    @Override protected void onPause() {
        super.onPause();
        if (gameView != null) gameView.pauseAnimation();
    }

    @Override protected void onDestroy() {
        if (connectivityManager != null && networkCallback != null) {
            connectivityManager.unregisterNetworkCallback(networkCallback);
        }
        super.onDestroy();
    }
}
