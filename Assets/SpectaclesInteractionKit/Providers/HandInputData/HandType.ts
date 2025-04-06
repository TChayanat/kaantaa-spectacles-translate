/**
 * Describes a hand type, can be left or right
 */
export const AllHandTypes = ["left", "right"] as const
<<<<<<< HEAD
export type HandType = (typeof AllHandTypes)[number]
=======
export type HandType = typeof AllHandTypes[number]
>>>>>>> crop
