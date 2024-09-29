using UnityEngine;
using System.Collections;
using UnityEngine.Audio; // Include this for AudioMixerGroup

public class PylonAmbiant : MonoBehaviour
{
    [Header("Audio Settings")]
    public AudioClip pylonSound; // The sound to play
    private AudioSource audioSource;

    [Header("Audio Mixer Settings")]
    public AudioMixerGroup audioMixerGroup; // Audio mixer group for output

    [Header("Distance Settings")]
    public float minDistance = 5f; // Minimum distance for sound to reach full volume
    public float maxDistance = 20f; // Maximum distance for sound to fade out
    public float volumeExponent = 2f; // Exponent to control how sharp the volume changes

    [Header("Health-Based Audio Settings")]
    public float defaultVolume = 1f; // Default volume when the player is at full health
    public float maxEchoEffect = 0.8f; // Maximum echo at low health
    public float maxDistortionEffect = 0.5f; // Maximum distortion at low health
    public float fadeOutDuration = 3f; // Fade out duration when health reaches 0

    [Header("References")]
    public Transform playerTransform; // Assign this in the Inspector

    private bool fadingOut = false;

    void Start()
    {
        // Initialize AudioSource and preload audio
        audioSource = gameObject.AddComponent<AudioSource>();
        audioSource.clip = pylonSound;
        audioSource.loop = true;
        audioSource.playOnAwake = false;
        audioSource.volume = 0f; // Set volume to 0 initially

        // Assign the audio mixer group to the AudioSource
        if (audioMixerGroup != null)
        {
            audioSource.outputAudioMixerGroup = audioMixerGroup;
        }

        // Preload audio by playing it muted
        audioSource.Play();
        audioSource.mute = true;

        // Pre-add audio filters so that they don't cause stutter when added later
        AddAudioFilters();

        // After preloading, unmute the audio but keep volume at 0
        StartCoroutine(UnmuteAfterPreload());

        // Start checking for nearby Pylons
        InvokeRepeating(nameof(CheckNearbyPylons), 0f, 0.1f);
    }

    private IEnumerator UnmuteAfterPreload()
    {
        // Wait for a short time to ensure audio is fully preloaded
        yield return new WaitForSeconds(0.1f);
        audioSource.mute = false; // Unmute audio
    }

    private void AddAudioFilters()
    {
        // Add and configure echo and distortion filters at the start
        if (audioSource.GetComponent<AudioEchoFilter>() == null)
        {
            var echoFilter = audioSource.gameObject.AddComponent<AudioEchoFilter>();
            echoFilter.delay = 50f;
            echoFilter.decayRatio = 0.5f;
        }

        if (audioSource.GetComponent<AudioDistortionFilter>() == null)
        {
            var distortionFilter = audioSource.gameObject.AddComponent<AudioDistortionFilter>();
            distortionFilter.distortionLevel = 0f;
        }
    }

    private void CheckNearbyPylons()
    {
        // Find all Pylon objects with the "Pylon" tag
        GameObject[] pylons = GameObject.FindGameObjectsWithTag("Pylon");

        // Track if we are playing any sound
        bool isPlaying = false;

        foreach (GameObject pylon in pylons)
        {
            float distance = Vector3.Distance(playerTransform.position, pylon.transform.position);

            // Check if the player is within the max distance
            if (distance <= maxDistance)
            {
                // Adjust volume based on distance
                float volume = CalculateVolume(distance);
                PlayPylonSound(volume);

                // Adjust audio effects based on player health
                float healthFactor = GetPlayerHealthFactor();
                AdjustAudioEffects(healthFactor);

                // Handle fading out when health reaches 0
                HandleHealthFadeOut(healthFactor);

                isPlaying = true; // Mark as playing sound
                break; // Exit after the first nearby Pylon
            }
        }

        // If no nearby Pylon is found, stop playing sound
        if (!isPlaying)
        {
            StopPylonSound();
        }
    }

    private float CalculateVolume(float distance)
    {
        // If the distance is less than minDistance, set volume to maximum
        if (distance < minDistance)
        {
            return defaultVolume; // Full volume
        }
        else if (distance > maxDistance)
        {
            return 0f; // No sound
        }

        // Normalize distance between 0 and 1
        float normalizedDistance = (distance - minDistance) / (maxDistance - minDistance);

        // Apply exponential curve to volume
        return defaultVolume * Mathf.Pow(1f - normalizedDistance, volumeExponent);
    }

    public void PlayPylonSound(float volume)
    {
        if (audioSource != null)
        {
            audioSource.volume = volume; // Set the calculated volume
            if (!audioSource.isPlaying) // Play sound only if it's not already playing
            {
                audioSource.Play();
            }
        }
    }

    private void StopPylonSound()
    {
        if (audioSource != null && audioSource.isPlaying && !fadingOut)
        {
            // Smoothly fade out the audio when health reaches 0
            fadingOut = true;
            StartCoroutine(FadeOutAudio(fadeOutDuration)); // Use fadeOutDuration for fade-out
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

    private void AdjustAudioEffects(float healthFactor)
    {
        // As health decreases, increase echo and distortion
        float echoAmount = Mathf.Lerp(0f, maxEchoEffect, 1 - healthFactor);
        float distortionAmount = Mathf.Lerp(0f, maxDistortionEffect, 1 - healthFactor);

        // Adjust echo and distortion filters based on health
        AudioEchoFilter echoFilter = audioSource.GetComponent<AudioEchoFilter>();
        echoFilter.delay = Mathf.Lerp(10f, 500f, 1 - healthFactor); // Echo delay increases as health decreases
        echoFilter.decayRatio = Mathf.Lerp(0.5f, 0.8f, 1 - healthFactor); // Decay ratio increases

        AudioDistortionFilter distortionFilter = audioSource.GetComponent<AudioDistortionFilter>();
        distortionFilter.distortionLevel = distortionAmount;

        // We will no longer reduce the volume based on health here
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
}
