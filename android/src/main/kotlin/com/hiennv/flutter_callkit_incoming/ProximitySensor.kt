package com.hiennv.flutter_callkit_incoming

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.PowerManager
import android.util.Log


class ProximitySensor(private val context: Context) : SensorEventListener {

   private lateinit var sensorManager: SensorManager
   private var proximitySensor: Sensor? = null
   private lateinit var powerManager: PowerManager
   private lateinit var wakeLock: PowerManager.WakeLock


   fun initialize() {
       // Initialize sensor and audio managers
       sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
       proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
       powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

       // Initialize wake lock (to control the screen)
       wakeLock = powerManager.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "EarpieceAudioPlugin::lock")

       // Register the proximity sensor listener
    //    if(proximitySensor !== null){
    //        sensorManager.registerListener(this, proximitySensor, SensorManager.SENSOR_DELAY_NORMAL)
    //    }

   }

   override fun onSensorChanged(event: SensorEvent) {
       if (event.sensor.type == Sensor.TYPE_PROXIMITY && proximitySensor !== null) {
           val distance = event.values[0]

           if (distance < proximitySensor!!.maximumRange) {
               // Device is close to the user's face
               if (!wakeLock.isHeld) {
                   wakeLock.acquire(3*60*60*1000L /*3 hours*/)
               }
           } else {
               // Device is away from the user's face
               if (wakeLock.isHeld) {
                   wakeLock.release()
               }
           }
       }
   }

   override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
       // Handle accuracy changes (if needed)
       Log.d("Proximity sensor", "Sensor accuracy has changed to accuracy $accuracy")
   }

   fun registerListener() {
       // Unregister the proximity sensor listener
       sensorManager.registerListener(this, proximitySensor, SensorManager.SENSOR_DELAY_NORMAL)

   }

   fun unregisterListener() {
       sensorManager.unregisterListener(this)

       // Release the wake lock
       if (wakeLock.isHeld) {
           wakeLock.release()
       }


   }
}