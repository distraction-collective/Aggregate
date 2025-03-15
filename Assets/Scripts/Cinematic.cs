using DesirePaths;
using StarterAssets;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Playables;

[RequireComponent(typeof(Collider))]
[RequireComponent(typeof(PlayableDirector))]

public class Cinematic : MonoBehaviour {
  public ThirdPersonController player;
  public PlayerHealth health;
  public GameObject respawnAt;
  public UnityEvent onCinematicEnd;

  SkinnedMeshRenderer[] skinnedMeshRenderers =>
      player.GetComponentsInChildren<SkinnedMeshRenderer>();
  ParticleSystemRenderer[] particleSystemRenderers =>
      player.GetComponentsInChildren<ParticleSystemRenderer>();
  PlayableDirector playableDirector => GetComponent<PlayableDirector>();
  bool played;
  float savedFootstepsAudioVolume;

  void OnTriggerEnter(Collider other) {
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
    savedFootstepsAudioVolume = player.FootstepAudioVolume;
    player.FootstepAudioVolume = 0f;
    foreach (var r in skinnedMeshRenderers) {
      r.enabled = false;
    }
    foreach (var r in particleSystemRenderers) {
      r.enabled = false;
    }
  }

  void OnAnimationEnd(PlayableDirector _) {
  // Restaurer le joueur à un nouveau point de respawn avec la bonne orientation
  Vector3 pos = respawnAt.transform.position;
  Quaternion rot = respawnAt.transform.rotation; // récupération de l'orientation
  
  health.respawn_position = pos;
  player.transform.position = pos;
  player.transform.rotation = rot; // application de l'orientation
  
  player.FootstepAudioVolume = savedFootstepsAudioVolume;
  
  if (health == null) {
    Debug.LogError("health is null");
  }
  if (health._puppetMaster == null) {
    Debug.LogError("puppet master is null");
  }
  
  // Utiliser la rotation de respawnAt pour la téléportation
  health._puppetMaster.Teleport(pos, rot, true);
  
  player.enabled = true;
  
  foreach (var r in skinnedMeshRenderers) {
    r.enabled = true;
  }
  foreach (var r in particleSystemRenderers) {
    r.enabled = true;
  }
  onCinematicEnd.Invoke();
}

}