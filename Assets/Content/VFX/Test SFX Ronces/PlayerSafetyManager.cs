using UnityEngine;

namespace DesirePaths // Make sure this matches your existing namespace
{
    public class PlayerSafetyManager : MonoBehaviour
    {
        public PlayerHealth playerHealth; // Reference to the Player Health script

        void Start()
        {
            // Ensure playerHealth is assigned
            if (playerHealth == null)
            {
                Debug.LogError("PlayerHealth is not assigned in the Inspector.");
            }
        }

        // Method to check if the player is safe
        public bool IsPlayerSafe()
        {
            // Using reflection to access the private 'safe' variable
            return playerHealth != null && (bool)playerHealth.GetType().GetField("safe", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance).GetValue(playerHealth);
        }
    }
}
