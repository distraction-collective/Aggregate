using System.Collections;
using System.Collections.Generic;
using RootMotion.Dynamics;
using StarterAssets;
using UnityEngine;

public class PlayFromHere : MonoBehaviour {
  public ThirdPersonController player;
  public PuppetMaster puppetMaster;
  void Start() {

    player.transform.position = transform.position;
    player.transform.rotation = transform.rotation;
    puppetMaster.Teleport(transform.position, transform.rotation, true);
  }
}
