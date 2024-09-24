using UnityEngine;
using UnityEngine.VFX; // Add this line for Visual Effects
using System.Reflection; // Required for Reflection

namespace DesirePaths
{
    public class PlayRoncesAudio : MonoBehaviour
    {
        public PlayerSafetyManager playerSafetyManager; // Reference to PlayerSafetyManager
        public AudioSource audioSource;                 // Reference to the audio source
        public AudioClip[] soundClips;                  // Array of audio clips to play
        public float minVolume = 0.1f;                  // Minimum volume level
        public float maxVolume = 0.6f;                  // Maximum volume level

        private VisualEffect vfx;                       // Reference to the Visual Effect component
        private float unsafeTime = 0f;                  // Time spent unsafe
        private float distortionRate = 0.2f;            // Rate at which distortion increases
        private float maxDistortion = 0.7f;               // Maximum distortion level
        private int lastPlayedIndex = -1;               // Index of the last played sound clip

        void Start()
        {
            // Find PlayerSafetyManager in the scene
            playerSafetyManager = FindObjectOfType<PlayerSafetyManager>();

            if (playerSafetyManager == null)
            {
                Debug.LogError("PlayerSafetyManager not found in the scene.");
            }

            // Get the VisualEffect component attached to the same GameObject
            vfx = GetComponent<VisualEffect>();

            // Ensure audioSource and sound clips are assigned
            if (audioSource == null)
            {
                Debug.LogError("AudioSource is not assigned in the Inspector.");
            }

            if (soundClips == null || soundClips.Length == 0)
            {
                Debug.LogError("No sound clips assigned in the Inspector.");
            }

            // Subscribe to the output event from the VFX Graph
            if (vfx != null)
            {
                vfx.outputEventReceived += OnVFXOutputEvent;
            }
        }

        void OnDestroy()
        {
            // Unsubscribe from the event when the object is destroyed to avoid memory leaks
            if (vfx != null)
            {
                vfx.outputEventReceived -= OnVFXOutputEvent;
            }
        }

        // This method is called whenever an output event is received from the VFX Graph
        private void OnVFXOutputEvent(VFXOutputEventArgs args)
        {
            // Check if the event corresponds to the particle spawn event
            if (args.nameId == Shader.PropertyToID("OnParticleSpawn")) // Ensure this matches the VFX event name
            {
                if (playerSafetyManager != null && !playerSafetyManager.IsPlayerSafe())
                {
                    PlayRandomSoundWithRandomVolume();
                    UpdateAudioEffects(); // Call to update audio effects
                }
            }
        }

        // Method to play a random sound with a random volume
        private void PlayRandomSoundWithRandomVolume()
        {
            if (audioSource != null && soundClips.Length > 0)
            {
                int randomIndex;

                // Ensure a different sound is played than the last one
                do
                {
                    randomIndex = Random.Range(0, soundClips.Length);
                } while (randomIndex == lastPlayedIndex); // Prevent playing the same sound

                lastPlayedIndex = randomIndex; // Update last played index

                // Select the random sound clip from the array
                AudioClip selectedClip = soundClips[randomIndex];

                // Set the selected clip in the audio source
                audioSource.clip = selectedClip;

                // Set a random volume between minVolume and maxVolume
                audioSource.volume = Random.Range(minVolume, maxVolume);

                // Play the sound
                audioSource.Play();
            }
            else
            {
                Debug.LogWarning("AudioSource or sound clips are not properly set.");
            }
        }

        // Method to update audio effects based on player health
        private void UpdateAudioEffects()
        {
            // Using reflection to get the current health and max health values
            PlayerHealth playerHealth = FindObjectOfType<PlayerHealth>();
            if (playerHealth != null)
            {
                // Get maxHealthValue using reflection
                float maxHealthValue = (float)playerHealth.GetType().GetField("maxHealthValue", BindingFlags.Public | BindingFlags.Instance).GetValue(playerHealth);

                // Get currentHealthValue using reflection
                float currentHealthValue = (float)playerHealth.GetType().GetField("_currentHealthValue", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(playerHealth);

                // Calculate health percentage
                float healthPercentage = currentHealthValue / maxHealthValue;

                // Calculate distortion value based on health
                float distortionValue = Mathf.Clamp01(1 - healthPercentage); // 0 = full health, 1 = no health
                distortionValue = distortionValue * maxDistortion; // Scale to maxDistortion

                // Apply distortion effect (example, assuming an AudioDistortionFilter exists)
                AudioDistortionFilter distortionFilter = audioSource.GetComponent<AudioDistortionFilter>();
                if (distortionFilter != null)
                {
                    distortionFilter.distortionLevel = distortionValue;
                }

                // Increase volume based on unsafe time
                float newVolume = Mathf.Clamp(minVolume + (unsafeTime * distortionRate), minVolume, maxVolume);
                audioSource.volume = newVolume;
            }
        }
    }
}
