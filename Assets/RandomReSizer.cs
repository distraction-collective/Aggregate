using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RandomReSizer : MonoBehaviour
{

    public float chanceNumber ;
    public int scaleNumber ;
    public Transform ObjectToResize ;

    // Start is called before the first frame update
    void Start()
    {

        StartCoroutine ("RandomChanceWithDelay", Random.Range(1,5));
        
    }

    // Update is called once per frame
    void Update()
    {
        ReSizer();
    }



    IEnumerator RandomChanceWithDelay(float delay) {
		while (true) {
			yield return new WaitForSeconds (delay);
			RandomChance();
		}
	}

    void RandomChance() {
		chanceNumber = Random.Range(0,100);
        scaleNumber = Random.Range(1,20);
	}

    void ReSizer() {
        if (ObjectToResize == null){ 
           ObjectToResize = this.gameObject.transform.GetChild(0).gameObject.transform;
  			return;
			}

        if(chanceNumber > 50 ){
           ObjectToResize.localScale = new Vector3(scaleNumber,scaleNumber,scaleNumber);
        }
        
		
	}
}
