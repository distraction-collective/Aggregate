using StarterAssets;
using UnityEngine;

public class Cadavers : MonoBehaviour {
  public GameObject[] corpses;
  public ThirdPersonController player;
  public void DepositCadaver() {
    int index = Random.Range(0, corpses.Length);
    GameObject corpse = corpses[index];
    RaycastHit hitInfo;
    bool isHit = Physics.Raycast(player.transform.position, Vector3.down,
                                 out hitInfo, Mathf.Infinity);
    Vector3 pos = isHit ? hitInfo.point : player.transform.position;
    Debug.Log($"{isHit} {hitInfo.point} {player.transform.position}");
    Instantiate(corpse, pos, Quaternion.identity);
  }
}
