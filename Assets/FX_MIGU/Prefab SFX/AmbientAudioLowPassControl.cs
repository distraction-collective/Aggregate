using UnityEngine;
using UnityEngine.Audio;
using System.Collections;

public class AmbientAudioLowPassControl : MonoBehaviour
{
    [Header("Audio Mixer Settings")]
    public AudioMixer audioMixer;                               // Reference to the AudioMixer
    public AudioMixerGroup audioMixerGroup;                    // The AudioMixerGroup for the active audio clip

    [Header("Audio Clip")]
    public AudioClip activeAudioClip;                           // The sound clip to play when the object is active
    public AudioSource activeAudioSource;                       // The AudioSource component for the active audio

    [Header("Target Object")]
    public GameObject targetObject;                             // The target object whose activation will trigger the audio

    [Header("Low-Pass Filter Control")]
    public float lowPassFrequencyWhenActive = 350f;            // Frequency when the target is active
    public float lowPassFrequencyWhenInactive = 22000f;        // Frequency when the target is inactive (full range)
    public float transitionDuration = 2f;                       // Duration for the frequency transition
    public string lowPassParameterName = "LowPassFrequency";    // Name of the low-pass filter parameter

    [Header("Activation Delay")]
    public float activationDelay = 0f;                          // Delay before audio starts playing when activated

    private void Start()
    {
        // Initialize the AudioSource for the active audio clip if not assigned
        if (activeAudioSource == null)
        {
            activeAudioSource = gameObject.AddComponent<AudioSource>();
        }

        // Assign the audio clip to the AudioSource
        activeAudioSource.clip = activeAudioClip;
        activeAudioSource.loop = true;
        activeAudioSource.playOnAwake = false;

        // Assign the audio mixer group if it exists
        if (audioMixerGroup != null)
        {
            activeAudioSource.outputAudioMixerGroup = audioMixerGroup;
        }

        // Preload the active audio clip by playing it muted and immediately pausing it
        activeAudioSource.volume = 1f; // Set the volume for AudioSource
        activeAudioSource.Play();
        activeAudioSource.Pause(); // This ensures the audio is preloaded but doesn't actually play

        // Set the initial low-pass filter frequency for ambient music
        SetLowPassFrequency(lowPassFrequencyWhenInactive);
    }

    private void Update()
    {
        if (targetObject.activeSelf)
        {
            OnTargetActivated();
        }
        else
        {
            OnTargetDeactivated();
        }
    }

    private void OnTargetActivated()
    {
        // Start the active audio with delay
        if (!activeAudioSource.isPlaying)
        {
            StartCoroutine(PlayActiveAudioWithDelay(activationDelay)); // Start playback with delay
        }

        // Smoothly transition to the active low-pass frequency
        StartCoroutine(TransitionLowPassFrequency(lowPassFrequencyWhenActive));
    }

    private void OnTargetDeactivated()
    {
        // Smoothly transition to the inactive low-pass frequency
        StartCoroutine(TransitionLowPassFrequency(lowPassFrequencyWhenInactive));

        // Stop the active audio when deactivated
        if (activeAudioSource.isPlaying)
        {
            activeAudioSource.Stop(); // Stop the audio completely
        }
    }

    private IEnumerator PlayActiveAudioWithDelay(float delay)
    {
        yield return new WaitForSeconds(delay); // Wait for the specified delay

        // Ensure active audio starts from the beginning each time
        activeAudioSource.Stop(); // Reset to the beginning before playing
        activeAudioSource.Play(); // Start playing the audio clip from the start
    }

    private IEnumerator TransitionLowPassFrequency(float targetFrequency)
    {
        // Smoothly transition to the target frequency over transitionDuration
        audioMixer.GetFloat(lowPassParameterName, out float currentFrequency); // Use the specified low pass parameter name

        float elapsed = 0f;

        while (elapsed < transitionDuration)
        {
            elapsed += Time.deltaTime;
            float newFrequency = Mathf.Lerp(currentFrequency, targetFrequency, elapsed / transitionDuration);
            SetLowPassFrequency(newFrequency);
            yield return null; // Wait for the next frame
        }

        // Ensure the target frequency is set at the end of the transition
        SetLowPassFrequency(targetFrequency);
    }

    private void SetLowPassFrequency(float frequency)
    {
        // Set the lowpass frequency for the ambient audio
        audioMixer.SetFloat(lowPassParameterName, frequency); // Use the specified low pass parameter name
    }
}
