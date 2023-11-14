using System.Collections;
using System.Collections.Generic;
using Cinemachine.Utility;
using UnityEngine;

public class AngelMeetPlayer : MonoBehaviour {
  public Transform player;
  public Animator animator;
  void Update() {
    float close = 5;
    float far = 50;
    float distance_on_ground = Vector3.Distance(
        transform.position.ProjectOntoPlane(new Vector3(0, 1, 0)),
        player.position.ProjectOntoPlane(new Vector3(0, 1, 0)));
    float factor = Mathf.InverseLerp(close, far, distance_on_ground);

    animator.SetLayerWeight(1, factor);
    transform.position =
        new Vector3(-40.7f, Mathf.Lerp(-13, 5, factor), -84.95f);
  }
}
