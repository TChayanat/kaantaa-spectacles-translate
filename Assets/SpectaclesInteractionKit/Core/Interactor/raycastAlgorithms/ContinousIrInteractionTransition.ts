import {inverseLerp} from "../../../Utils/mathUtils"
import {IrInteractionTransition} from "./IrInteractionTransition"

type ContinousIrInteractionTransitionConfig = {
  /**
   * Maximum rotation around X axis in degrees when the hand is in a low position
   */
  maximumRotationXDegrees: number

  /**
   * Minimum height difference between neck and hand to control X rotation
   */
  minNeckHandDifference: number

  /**
   * Maximum height difference between neck and hand to control X rotation
   */
  maxNeckHandDifference: number

  /**
   * Enable/Disable the counter effect controlled by the gaze pitch
   */
  enableGazeControl: boolean

  /**
   * Minimum gaze pitch in degrees to control X rotation
   */
  minGazePitchDegrees: number

  /**
   * Maximum gaze pitch in degrees to control X rotation
   */
  maxGazePitchDegrees: number
}

const ContinousIrInteractionTransitionConfigDefault = {
  maximumRotationXDegrees: 25,
  minNeckHandDifference: 10,
  maxNeckHandDifference: 45,
  enableGazeControl: false,
  minGazePitchDegrees: 25,
  maxGazePitchDegrees: 40,
}

/**
 * Class to implement Directly controlled continuous IR Transition Strategy
 */
export default class ContinuousIrInteractionTransition
  implements IrInteractionTransition
{
  /** @inheritdoc */
  computeXRotationInDegrees(
    gazePitchInDegrees: number,
    toWorldFromSituationSpace: mat4,
<<<<<<< HEAD
    handPoint: vec3,
=======
    handPoint: vec3
>>>>>>> crop
  ): number {
    const transformedHandPoint = toWorldFromSituationSpace
      .inverse()
      .multiplyPoint(handPoint)

    const rotationInDegrees =
      this.computeMultiplier(transformedHandPoint, gazePitchInDegrees) *
      ContinousIrInteractionTransitionConfigDefault.maximumRotationXDegrees
    return rotationInDegrees
  }

  /** @inheritdoc */
  computeXRotationInRadians(
    gazePitchInRadians: number,
    toWorldFromSituationSpace: mat4,
<<<<<<< HEAD
    handPoint: vec3,
=======
    handPoint: vec3
>>>>>>> crop
  ): number {
    return (
      MathUtils.DegToRad *
      this.computeXRotationInDegrees(
        MathUtils.RadToDeg * gazePitchInRadians,
        toWorldFromSituationSpace,
<<<<<<< HEAD
        handPoint,
=======
        handPoint
>>>>>>> crop
      )
    )
  }

  /**
   * Computes the multiplier for the Ir interaction additional rotation in continuous transition mode
   * @param handPoint - hand point used for height estimation
   * @param gazePitchInDegrees - gaze pitch given in degrees
   * @returns multiplier for the Ir interaction interaction rotation
   */
  private computeMultiplier(
    handPoint: vec3,
<<<<<<< HEAD
    gazePitchInDegrees: number,
=======
    gazePitchInDegrees: number
>>>>>>> crop
  ): number {
    const effect = MathUtils.clamp(
      inverseLerp(
        -ContinousIrInteractionTransitionConfigDefault.minNeckHandDifference,
        -ContinousIrInteractionTransitionConfigDefault.maxNeckHandDifference,
<<<<<<< HEAD
        handPoint.y,
      ),
      0,
      1,
=======
        handPoint.y
      ),
      0,
      1
>>>>>>> crop
    )

    const counterEffect =
      ContinousIrInteractionTransitionConfigDefault.enableGazeControl
        ? MathUtils.clamp(
            inverseLerp(
              -ContinousIrInteractionTransitionConfigDefault.minGazePitchDegrees,
              -ContinousIrInteractionTransitionConfigDefault.maxGazePitchDegrees,
<<<<<<< HEAD
              gazePitchInDegrees,
            ),
            0,
            1,
=======
              gazePitchInDegrees
            ),
            0,
            1
>>>>>>> crop
          )
        : 0
    return MathUtils.clamp(effect - counterEffect, 0, 1)
  }
}
