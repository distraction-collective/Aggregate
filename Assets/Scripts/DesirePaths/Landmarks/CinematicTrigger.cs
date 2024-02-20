using UnityEngine;
using UnityEngine.Playables;

namespace DesirePaths.Landmarks {

  [RequireComponent(typeof(BoxCollider))]
  [RequireComponent(typeof(PlayableDirector))]

  public class CinematicTrigger : MonoBehaviour {
    private PlayableDirector playableDirector =>
        GetComponent<PlayableDirector>();

    private void OnTriggerEnter(Collider other) {
      if (other.gameObject.CompareTag("Player_Collider")) {
        Debug.Log("start cinematic");
        playableDirector.Play();
        playableDirector.stopped += OnAnimationEnd;
      }
    }

    private void OnAnimationEnd(PlayableDirector _) {
      Debug.Log("end cinematic");
    }
  }
}