using System.Collections;
using System.Collections.Generic;
using DesirePaths;
using RootMotion.Dynamics;
using StarterAssets;
using UnityEngine;

public class PlayFromHere : MonoBehaviour {
  public ThirdPersonController player;
  public PuppetMaster puppetMaster;
  public PlayerHealth health;
  void Start() {
    player.transform.position = transform.position;
    puppetMaster.Teleport(transform.position, player.transform.rotation, true);
    health.respawn_position = transform.position;
  }
}
