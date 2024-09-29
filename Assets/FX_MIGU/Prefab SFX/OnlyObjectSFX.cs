using UnityEngine;
using System.Collections; // Needed for coroutines
using UnityEngine.Audio;

public class OnlyObjectSFX : MonoBehaviour
{
    [Header("Audio Settings")]
    public AudioClip objectSound; // The sound to play
    private AudioSource audioSource;

    [Header("Audio Mixer Settings")]
    public AudioMixerGroup audioMixerGroup; // Audio mixer group for output

    [Header("Distance Settings")]
    public float minDistance = 5f; // Minimum distance for sound to reach full volume
    public float maxDistance = 20f; // Maximum distance for sound to fade out
    public float volumeExponent = 2f; // Exponent to control how sharp the volume changes
    public float defaultVolume = 1f; // Default volume when close

    [Header("Health-Based Audio Settings")]
    public float fadeOutDuration = 3f; // Fade out duration when health reaches 0

    [Header("References")]
    public Transform soundObject; // The object that emits sound
    public Transform playerTransform; // The player character's transform

    private bool fadingOut = false;

    void Start()
    {
        // Initialize AudioSource and set up audio
        audioSource = gameObject.AddComponent<AudioSource>();
        audioSource.clip = objectSound;
        audioSource.loop = true;
        audioSource.playOnAwake = false;
        audioSource.volume = 0f; // Start with volume at 0

        // Assign the audio mixer group if it exists
        if (audioMixerGroup != null)
        {
            audioSource.outputAudioMixerGroup = audioMixerGroup;
        }

        // Start playing the sound muted
        audioSource.Play();
        audioSource.mute = false;

        // Repeatedly check the distance from the player to the object
        InvokeRepeating(nameof(CheckDistanceToObject), 0f, 0.1f);
    }

    void CheckDistanceToObject()
    {
        if (soundObject != null && playerTransform != null)
        {
            float distance = Vector3.Distance(playerTransform.position, soundObject.position);
            float volume = CalculateVolume(distance);
            audioSource.volume = volume;

            // Handle fading out when health reaches 0
            float healthFactor = GetPlayerHealthFactor();
            HandleHealthFadeOut(healthFactor);
        }
    }

    float CalculateVolume(float distance)
    {
        // Ensure the volume is 0 if the player is beyond maxDistance
        if (distance >= maxDistance)
        {
            return 0f; // No sound
        }

        // If the distance is less than minDistance, set volume to maximum
        if (distance <= minDistance)
        {
            return defaultVolume; // Full volume
        }

        // Normalize distance between 0 and 1
        float normalizedDistance = (distance - minDistance) / (maxDistance - minDistance);

        // Apply exponential curve to volume
        return defaultVolume * Mathf.Pow(1f - normalizedDistance, volumeExponent);
    }

    private float GetPlayerHealthFactor()
    {
        // Using GetComponent to access the PlayerHealth class indirectly.
        MonoBehaviour playerHealthScript = playerTransform.GetComponent<MonoBehaviour>();

        if (playerHealthScript != null)
        {
            // Access the current health and max health values using reflection
            var currentHealth = playerHealthScript.GetType().GetField("_currentHealthValue", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var maxHealth = playerHealthScript.GetType().GetField("maxHealthValue", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);

            if (currentHealth != null && maxHealth != null)
            {
                float currentHealthValue = (float)currentHealth.GetValue(playerHealthScript);
                float maxHealthValue = (float)maxHealth.GetValue(playerHealthScript);

                // Return health factor as a value between 0 and 1
                return currentHealthValue / maxHealthValue;
            }
        }

        return 1f; // Default to full health if playerHealthScript is not found or fails
    }

    private void HandleHealthFadeOut(float healthFactor)
    {
        // Start fading out when health reaches 0
        if (healthFactor <= 0f && !fadingOut)
        {
            StartCoroutine(FadeOutAudio(fadeOutDuration));
        }
        // Restore normal volume when health is restored
        else if (healthFactor > 0f && fadingOut)
        {
            audioSource.volume = defaultVolume;
            fadingOut = false;
        }
    }

    private IEnumerator FadeOutAudio(float fadeDuration)
    {
        float startVolume = audioSource.volume;

        for (float t = 0; t < fadeDuration; t += Time.deltaTime)
        {
            audioSource.volume = Mathf.Lerp(startVolume, 0, t / fadeDuration);
            yield return null;
        }

        audioSource.Stop();
        audioSource.volume = startVolume; // Reset volume to original
        fadingOut = false;
    }
}
