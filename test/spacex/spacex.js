module.exports = {
    getSpaceXData: async () => {
    try {
      const response = await axios.get('https://api.spacexdata.com/v3/launchpads')
      return response.data
    } catch (error) {
      return error
    }
  }
};
