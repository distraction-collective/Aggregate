using DesirePaths;
using StarterAssets;
using UnityEngine;
using UnityEngine.Playables;

[RequireComponent(typeof(Collider))]
[RequireComponent(typeof(PlayableDirector))]

public class SimpleCinematicTrigger : MonoBehaviour {
  public ThirdPersonController player;
  public PlayerHealth health;
  private SkinnedMeshRenderer[] skinnedMeshRenderers =>
      player.GetComponentsInChildren<SkinnedMeshRenderer>();
  private ParticleSystemRenderer[] particleSystemRenderers =>
      player.GetComponentsInChildren<ParticleSystemRenderer>();
  private PlayableDirector playableDirector => GetComponent<PlayableDirector>();
  private bool played;

  private void OnTriggerEnter(Collider other) {
    if (played)
      return;
    if (!other.gameObject.CompareTag("Player_Collider"))
      return;

    // play the cinematic once
    played = true;
    playableDirector.Play();
    playableDirector.stopped += OnAnimationEnd;

    // hide the player
    player.enabled = false;
    foreach (var r in skinnedMeshRenderers) {
      r.enabled = false;
    }
    foreach (var r in particleSystemRenderers) {
      r.enabled = false;
    }
  }

  private void OnAnimationEnd(PlayableDirector _) {
    // restore the player
    player.enabled = true;
    foreach (var r in skinnedMeshRenderers) {
      r.enabled = true;
    }
    foreach (var r in particleSystemRenderers) {
      r.enabled = true;
    }
    health.respawn_position = player.transform.position;
    health.respawn_rotation = player.transform.rotation;
  }
}