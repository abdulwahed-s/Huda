package com.aw.huda.miqaat

import com.aw.huda.R
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.app.Activity
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.PaintDrawable
import android.graphics.drawable.ShapeDrawable
import android.graphics.drawable.shapes.RectShape
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Space
import android.widget.TextView


class MiqaatLockOverlayActivity : Activity() {

    private var packageName: String? = null
    private var goalDuration: Int = 10


    private var bgGradientStart = 0
    private var bgGradientMid = 0
    private var bgGradientEnd = 0
    private var cardBgColor = 0
    private var accentStart = 0
    private var accentEnd = 0
    private var textPrimary = 0
    private var textSecondary = 0
    private var textAccent = 0
    private var dividerColor = 0
    private var outlineColor = 0
    private var iconBgColor = 0
    private var iconStrokeColor = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        packageName = intent.getStringExtra("package_name")
        goalDuration = intent.getIntExtra("goal_duration", 10)


        resolveThemeColors()


        window.apply {
            addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            statusBarColor = bgGradientStart
            navigationBarColor = bgGradientStart
        }

        setupUI()
    }

    private fun isDarkMode(): Boolean {
        return (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
    }

    private fun resolveThemeColors() {
        if (isDarkMode()) {

            bgGradientStart = Color.parseColor("#0d1117")
            bgGradientMid = Color.parseColor("#0f2027")
            bgGradientEnd = Color.parseColor("#1a1a2e")
            cardBgColor = Color.argb(230, 28, 35, 51)
            textPrimary = Color.parseColor("#F0F6FC")
            textSecondary = Color.parseColor("#9CA3AF")
            textAccent = Color.parseColor("#00C9A7")
            dividerColor = Color.parseColor("#2D3748")
            outlineColor = Color.parseColor("#4A5568")
            iconBgColor = Color.argb(40, 0, 201, 167)
            iconStrokeColor = Color.argb(60, 0, 201, 167)
        } else {

            bgGradientStart = Color.parseColor("#F5F7FA")
            bgGradientMid = Color.parseColor("#E8ECF1")
            bgGradientEnd = Color.parseColor("#DCE2E9")
            cardBgColor = Color.argb(240, 255, 255, 255)
            textPrimary = Color.parseColor("#1A202C")
            textSecondary = Color.parseColor("#64748B")
            textAccent = Color.parseColor("#009D84")
            dividerColor = Color.parseColor("#E2E8F0")
            outlineColor = Color.parseColor("#94A3B8")
            iconBgColor = Color.argb(25, 0, 180, 150)
            iconStrokeColor = Color.argb(50, 0, 180, 150)
        }
        accentStart = Color.parseColor("#00C9A7")
        accentEnd = Color.parseColor("#00BFA5")
    }


    private fun dp(value: Int): Int =
        TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()

    private fun setupUI() {

        val root = FrameLayout(this).apply {
            val gradient = PaintDrawable()
            gradient.shape = RectShape()
            gradient.shaderFactory = object : ShapeDrawable.ShaderFactory() {
                override fun resize(width: Int, height: Int): Shader {
                    return LinearGradient(
                        0f, 0f, 0f, height.toFloat(),
                        intArrayOf(bgGradientStart, bgGradientMid, bgGradientEnd),
                        floatArrayOf(0f, 0.4f, 1f),
                        Shader.TileMode.CLAMP
                    )
                }
            }
            background = gradient
        }


        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(32), dp(40), dp(32), dp(36))
            val cardDrawable = GradientDrawable().apply {
                setColor(cardBgColor)
                cornerRadius = dp(28).toFloat()
            }
            background = cardDrawable
            elevation = dp(8).toFloat()


            alpha = 0f
            translationY = dp(40).toFloat()
        }


        val iconContainer = FrameLayout(this).apply {
            val size = dp(88)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(20)
            }
        }
        val iconBg = View(this).apply {
            val circle = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(iconBgColor)
                setStroke(dp(2), iconStrokeColor)
            }
            background = circle
            layoutParams = FrameLayout.LayoutParams(dp(88), dp(88))
        }
        val iconText = TextView(this).apply {
            text = "🕌"
            textSize = 40f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        iconContainer.addView(iconBg)
        iconContainer.addView(iconText)
        card.addView(iconContainer)


        val title = TextView(this).apply {
            text = getString(R.string.miqaat_lock_title)
            textSize = 30f
            setTextColor(textPrimary)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER
            letterSpacing = 0.02f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(10)
            }
        }
        card.addView(title)


        val message = TextView(this).apply {
            text = getString(R.string.miqaat_lock_message)
            textSize = 15f
            setTextColor(textSecondary)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setLineSpacing(dp(4).toFloat(), 1f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(20)
            }
        }
        card.addView(message)


        val divider = View(this).apply {
            setBackgroundColor(dividerColor)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(1)
            ).apply {
                leftMargin = dp(16)
                rightMargin = dp(16)
                bottomMargin = dp(20)
            }
        }
        card.addView(divider)


        val goalInfo = TextView(this).apply {
            text = getString(R.string.miqaat_lock_goal_info, goalDuration)
            textSize = 14f
            setTextColor(textAccent)
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setLineSpacing(dp(3).toFloat(), 1f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dp(32)
            }
        }
        card.addView(goalInfo)


        val ctaButton = TextView(this).apply {
            text = getString(R.string.miqaat_lock_open_huda)
            textSize = 17f
            setTextColor(Color.WHITE)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
            gravity = Gravity.CENTER
            letterSpacing = 0.03f
            setPadding(dp(48), dp(16), dp(48), dp(16))
            val pillBg = GradientDrawable().apply {
                orientation = GradientDrawable.Orientation.LEFT_RIGHT
                colors = intArrayOf(accentStart, accentEnd)
                cornerRadius = dp(50).toFloat()
            }
            background = pillBg
            elevation = dp(4).toFloat()
            isClickable = true
            isFocusable = true
            setOnClickListener { openHudaApp() }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dp(16)
            }
        }
        card.addView(ctaButton)


        card.addView(Space(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(4)
            )
        })


        val backButton = TextView(this).apply {
            text = getString(R.string.miqaat_lock_go_back)
            textSize = 14f
            setTextColor(outlineColor)
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(dp(36), dp(12), dp(36), dp(12))
            val outlineBg = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                setStroke(dp(1), outlineColor)
                cornerRadius = dp(50).toFloat()
            }
            background = outlineBg
            isClickable = true
            isFocusable = true
            setOnClickListener { goHome() }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }
        card.addView(backButton)


        val cardParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = Gravity.CENTER
            leftMargin = dp(24)
            rightMargin = dp(24)
        }
        root.addView(card, cardParams)
        setContentView(root)


        card.post {
            val fadeIn = ObjectAnimator.ofFloat(card, "alpha", 0f, 1f)
            val slideUp = ObjectAnimator.ofFloat(card, "translationY", dp(40).toFloat(), 0f)
            AnimatorSet().apply {
                playTogether(fadeIn, slideUp)
                duration = 500
                interpolator = DecelerateInterpolator(1.5f)
                start()
            }
        }
    }

    private fun openHudaApp() {
        val intent = packageManager.getLaunchIntentForPackage("com.aw.huda")
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
        finish()
    }

    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        finish()
    }

    override fun onBackPressed() {
        goHome()
    }
}
