
using StarterAssets;
using UnityEngine;

public class Cadavers : MonoBehaviour {
  public GameObject[] corpses;
  public ThirdPersonController player;
  public void DepositCadaver() {

    int index = Random.Range(0, corpses.Length);
    GameObject corpse = corpses[index];
    Instantiate(corpse, player.transform.position, Quaternion.identity);
  }
}
