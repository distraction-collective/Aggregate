using StarterAssets;
using UnityEngine;
using UnityEngine.Playables;

namespace DesirePaths.Landmarks {

  [RequireComponent(typeof(BoxCollider))]
  [RequireComponent(typeof(PlayableDirector))]

  public class CinematicTrigger : MonoBehaviour {
    public GameObject player;
    public GameObject corpses;
    private SkinnedMeshRenderer[] skinnedMeshRenderers;
    private ParticleSystemRenderer[] particleSystemRenderers;
    private ThirdPersonController controller;
    private bool played;
    private PlayableDirector playableDirector =>
        GetComponent<PlayableDirector>();

    void Awake() {
      controller = player.GetComponent<ThirdPersonController>();
      if (controller == null) {
        Debug.LogError("player should have a ThirdPersonController component");
      }
    }

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
      controller.enabled = false;
      skinnedMeshRenderers =
          player.GetComponentsInChildren<SkinnedMeshRenderer>();
      foreach (var r in skinnedMeshRenderers) {
        r.enabled = false;
      }
      particleSystemRenderers =
          player.GetComponentsInChildren<ParticleSystemRenderer>();
      foreach (var r in particleSystemRenderers) {
        r.enabled = false;
      }
    }

    private void OnAnimationEnd(PlayableDirector _) {
      // restore the player
      controller.enabled = true;
      foreach (var r in skinnedMeshRenderers) {
        r.enabled = true;
      }
      foreach (var r in particleSystemRenderers) {
        r.enabled = true;
      }

      // keep corpses from the animation
      corpses.SetActive(true);
    }
  }
}