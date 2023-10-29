using System.Collections;
using System.Collections.Generic;
using MonsterLove.Collections;
using UnityEngine;
using UnityEngine.Splines;

public class CadaverGutsManager : MonoBehaviour
{
    [Header("Player Info")]
    public Transform _gutsOrigin;
    public Transform playerTransform;
    [Header("Cadavers and splines")]
    public List<GameObject> currentCadaverArray = new List<GameObject>();
    public SplineContainer _splineContainer;
    public SplineExtrude _splineGeometry;
    [Header("Data")]
    [SerializeField] private PoolManager cadaverPool;
    [SerializeField] private CadaverData _data;

    //Raycasts
    RaycastHit _hit;
    
    // Start is called before the first frame update
    void Start()
    {
        InitializePool();
        InitializeOriginKnot();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    /// <summary>
    /// Deposits cadaver at playerTransform Position, using a raycast above player and pointing downwards,
    /// we get the exact position and normal offset where we should put the body
    /// </summary>

    public void DepositeCadaverOnPosition()
    {
        GameObject newCadaver;
        int randPrefabIndex = Random.Range(0, _data.randomCadaverPrefabs.Length); //Lets choose a random prefab
        if (Physics.Raycast(playerTransform.position + Vector3.up * _data.basicDetectionHeightDifferential, -Vector3.up, out _hit, Mathf.Infinity, _data.layerToPutCadaver)){
            var randPrefab = _data.randomCadaverPrefabs[randPrefabIndex];
            newCadaver = cadaverPool.spawnObject(randPrefab, _hit.point, Quaternion.identity);
            currentCadaverArray.Add(newCadaver);
            newCadaver.transform.rotation = Quaternion.FromToRotation(transform.up, _hit.normal) * newCadaver.transform.rotation;
        }
        else //We failed to hit, proceed to just put it where playerTransform is - itll be ugly but it still works
        {
            var randPrefab = _data.randomCadaverPrefabs[randPrefabIndex];
            newCadaver = cadaverPool.spawnObject(randPrefab, playerTransform.position + Vector3.up * _data.cadaverDepositExtraHeight, Quaternion.identity);
            currentCadaverArray.Add(newCadaver);
        }
        ConnectSplineToNewCadaver(newCadaver.transform);
    }

    public void ConnectSplineToNewCadaver(Transform newCadaverTransform)
    {
        _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(newCadaverTransform.position + Vector3.up * _data.cadaverDepositExtraHeight)));
        _splineGeometry.Rebuild(); //Rebuild geometry to accomodate new spline knot 
    }

    public void InitializeOriginKnot()
    {
        _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(_gutsOrigin.position + Vector3.up * _data.cadaverDepositExtraHeight)));
        _splineContainer.Spline.SetTangentMode(TangentMode.Continuous);
        _splineGeometry.Rebuild(); //Rebuild geometry to accomodate new spline knot 
    }

    void InitializePool()
    {
        foreach (var cadaverPrefab in _data.randomCadaverPrefabs)
        {
            cadaverPool.warmPool(cadaverPrefab, _data.maxPopPerPrefab);
        }
    }
}
