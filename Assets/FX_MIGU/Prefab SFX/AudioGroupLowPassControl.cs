using UnityEngine;
using UnityEngine.Audio;

public class AmbientAudioLowPassControl : MonoBehaviour
{
    [Header("Audio Mixer Settings")]
    public AudioMixer audioMixer;                               // Reference to the AudioMixer
    public string ambientAudioGroupName = "General Volume";    // The AudioMixerGroup for the ambient audio
    public string lowPassParameterName = "YourLowPassParameter"; // The exposed parameter for lowpass filter

    [Header("Audio Clip")]
    public AudioClip activeAudioClip;                           // The sound clip to play when the object is active
    public AudioMixerGroup activeAudioMixerGroup;              // AudioMixerGroup for the active audio
    private AudioSource activeAudioSource;                      // The AudioSource component for the active audio

    [Header("Target Object")]
    public GameObject targetObject;                             // The target object whose activation will trigger the audio

    [Header("Low-Pass Filter Control")]
    public float lowPassFrequencyWhenActive = 130f;            // Frequency when the target is active
    public float lowPassFrequencyWhenInactive = 22000f;        // Frequency when the target is inactive (full range)

    [Header("Activation Delay")]
    public float initialActivationDelay = 1f;                  // Delay before audio starts playing when activated

    private float delayCounter = 0f;                            // Counter to track the delay
    private bool isDelayActive = false;                         // To check if delay is active

    private void Start()
    {
        // Initialize the AudioSource for the active audio clip
        activeAudioSource = gameObject.AddComponent<AudioSource>();
        activeAudioSource.clip = activeAudioClip;
        activeAudioSource.outputAudioMixerGroup = activeAudioMixerGroup; // Link to the audio mixer group
        activeAudioSource.loop = true;
        activeAudioSource.playOnAwake = false;

        // Preload the active audio clip
        activeAudioSource.volume = 1f; // Set the volume for AudioSource
        activeAudioSource.Play();
        activeAudioSource.Pause(); // Ensure the audio is preloaded but doesn't actually play

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
        // If the audio isn't playing and delay isn't active, start the delay counter
        if (!activeAudioSource.isPlaying && !isDelayActive)
        {
            isDelayActive = true; // Set the delay active
            delayCounter = initialActivationDelay; // Start the delay counter
        }

        // Update the delay counter
        if (isDelayActive)
        {
            delayCounter -= Time.deltaTime; // Decrease the counter by the frame time

            // Check if the delay has elapsed
            if (delayCounter <= 0f)
            {
                activeAudioSource.Stop(); // Reset to the beginning before playing
                activeAudioSource.Play(); // Start playing the audio clip from the start
                isDelayActive = false; // Reset the delay
            }
        }

        // Set the low-pass filter for the ambient music
        SetLowPassFrequency(lowPassFrequencyWhenActive);
    }

    private void OnTargetDeactivated()
    {
        // Set the low-pass filter for the ambient music back to full range
        SetLowPassFrequency(lowPassFrequencyWhenInactive);

        // Stop the active audio when deactivated
        if (activeAudioSource.isPlaying)
        {
            activeAudioSource.Stop(); // Stop the audio completely
        }

        // Reset the delay
        isDelayActive = false;
        delayCounter = 0f;
    }

    private void SetLowPassFrequency(float frequency)
    {
        // Set the lowpass frequency for the ambient audio
        audioMixer.SetFloat(lowPassParameterName, frequency);
    }
}
