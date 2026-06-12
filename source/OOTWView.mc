import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.Time.Gregorian as Date;
using Toybox.Weather;


// https://github.com/kevin940726/shy-watch-face/blob/main/source/ShyView.mc#L26

class OOTWView extends WatchUi.WatchFace {

    private var BiggPS;
    private var SmolPS;
    private var cx;
    private var cy;
    private var isLowPowerMode = false;
    private var isHidden = false;

    function initialize() {
        WatchFace.initialize();
        BiggPS = Graphics.FONT_NUMBER_THAI_HOT;
        SmolPS = Application.loadResource(Rez.Fonts.SmolTT);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        cx = 180;
        cy = 180;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        isHidden = false;
    }

    // Update the view
    // This function is run every minute (?) to update the watch face contents
    function onUpdate(dc as Dc) as Void {

        View.onUpdate(dc);

        // Draw the UI
        drawHoursMinutes(dc);

        if (!isLowPowerMode && !isHidden) {
            drawHighPower(dc);
        } else {
            drawLowPower(dc);
        }
    }

    private function drawHoursMinutes(dc) {
        var clockTime = System.getClockTime();
        var hours = clockTime.hour.format("%02d");
        var minutes = clockTime.min.format("%02d");

        // Draw full time — dim in low-power/hidden mode for AMOLED
        var timeColor = (isLowPowerMode || isHidden) ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE;
        dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy,
            BiggPS,
            hours+":"+minutes,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawHighPower(dc) {

        // date
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_MEDIUM);

        // Draw Day of the week
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);        
        dc.drawText(
            cx,
            cy-75,
            SmolPS,
            Lang.format("$1$", [date.day_of_week]).toUpper() + "    " + Lang.format("$1$", [date.day]).toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // bottom row: weather (left), steps (center), HR (right)
        var info = ActivityMonitor.getInfo();
        var steps_str = info.steps < 1000
            ? info.steps.format("%d")
            : (info.steps / 1000.0).format("%.1f") + "K";
        var temperature_str = Weather.getCurrentConditions().temperature.format("%0.0f");

        var heartRate = Activity.getActivityInfo().currentHeartRate;
        if (heartRate == null && (ActivityMonitor has :getHeartRateHistory)) {
            var HRS = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (HRS != null && HRS.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                heartRate = HRS.heartRate;
            }
        }
        var heartRate_str = heartRate != null ? heartRate.format("%d") : "---";

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx-100,
            cy+75,
            SmolPS,
            temperature_str+" °C",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            cx,
            cy+75,
            SmolPS,
            steps_str,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            cx+100,
            cy+75,
            SmolPS,
            heartRate_str,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // top row: battery only, centered
        var battery_str = System.getSystemStats().battery.format("%02d");
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cx,
            cy-135,
            SmolPS,
            battery_str + " %",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    private function drawLowPower(dc) {
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_MEDIUM);
        // Draw Day of the week
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);        
        dc.drawText(
            cx,
            cy-75,
            SmolPS,
            Lang.format("$1$", [date.day_of_week]).toUpper() + "    " + Lang.format("$1$", [date.day]).toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function onHide() as Void {
        isHidden = true;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isLowPowerMode = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isLowPowerMode = true;
    }

}
