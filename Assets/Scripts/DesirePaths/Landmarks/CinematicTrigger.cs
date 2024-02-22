using StarterAssets;
using UnityEngine;
using UnityEngine.Playables;

namespace DesirePaths.Landmarks {

  [RequireComponent(typeof(BoxCollider))]
  [RequireComponent(typeof(PlayableDirector))]

  public class CinematicTrigger : MonoBehaviour {
    public GameObject player;
    private SkinnedMeshRenderer[] renderers;
    private bool played;
    private PlayableDirector playableDirector =>
        GetComponent<PlayableDirector>();

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
      player.GetComponent<ThirdPersonController>().enabled = false;
      renderers = player.GetComponentsInChildren<SkinnedMeshRenderer>();
      foreach (SkinnedMeshRenderer renderer in renderers) {
        renderer.enabled = false;
      }
    }

    private void OnAnimationEnd(PlayableDirector _) {
      // restore the player
      player.GetComponent<ThirdPersonController>().enabled = true;
      foreach (SkinnedMeshRenderer renderer in renderers) {
        renderer.enabled = true;
      }
    }
  }
}