using UnityEngine;

[CreateAssetMenu(fileName = "Data", menuName = "ScriptableObjects/CadaverData", order = 1)]
public class CadaverData: ScriptableObject
{
    public LayerMask layerToPutCadaver;
    public GameObject[] randomCadaverPrefabs;
    [Tooltip("How much of a single prefab we pool onStart()")]
    public int maxPopPerPrefab;
    public int maxNumberOfKnotsBetweenCadavers = 2;
    public float basicDetectionHeightDifferential = 10f;
    public float cadaverDepositExtraHeight = 0.5f;
}